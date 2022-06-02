//Noesis Build Engine import support.
//written for c++98/03 using Ken Silverman's BUILDINF.txt, with some bits of the vanilla Build source for reference.
#include "stdafx.h"

#include "../../misc_util/RichPoly2D.h"

buildMapOpts_t *g_buildMapOpts = NULL;

namespace
{
	const uint32_t skMaxSectorWalkAttemptCount = 4096;
	
	const uint32_t skMaxArtFileCount = 1024;

	const uint32_t skSinglePaletteEntryCount = 256;
	const uint32_t skSinglePaletteChannelCount = 3;
	const uint32_t skSinglePaletteSize = skSinglePaletteEntryCount * skSinglePaletteChannelCount;
	const uint32_t skSingleShadingTableSize = 256;

	const uint32_t skSpriteSpecialPicIndexBegin = 1; //SECTOREFFECTOR
	const uint32_t skSpriteSpecialPicIndexEnd = 10; //GPSPEED
	const uint32_t skShadowWarriorStSprite = 2307;
	const int32_t skMaxBuildMapDimension = 1024 * 1024;
	const float skSpriteFudgeDistance = 4.0f;
	const float skSpriteCloseEnoughToWallSquared = skSpriteFudgeDistance * skSpriteFudgeDistance;
	const float skSpriteCloseEnoughToFloor = 2.0f;

	struct SMapSectorInfo
	{
		SMapSectorInfo(const bool isCCW)
			: mIsCCW(isCCW)
		{
		}
		bool mIsCCW;
	};
	typedef std::vector<SMapSectorInfo> TMapSectorInfoList;

	struct SMapHeader
	{
		int32_t mVersion;
		int32_t mStartPos[3];
		int16_t mAngle;
		uint16_t mStartSector;
	};

	struct SMapSector
	{
		int16_t mWallIndex;
		int16_t mWallCount;

		int32_t mCeilingZ;
		int32_t mFloorZ;

		int16_t mCeilStat;
		int16_t mFloorStat;

		int16_t mCeilingPicIndex;
		int16_t mCeilingHeiNum; //slope value - "(0-parallel to floor, 4096-45 degrees)"

		int8_t mCeilingShade;
		uint8_t mCeilingPal;
		uint8_t mCeilingXPan;
		uint8_t mCeilingYPan;

		int16_t mFloorPicIndex;
		int16_t mFloorHeiNum;
		int8_t mFloorShade;
		uint8_t mFloorPal;
		uint8_t mFloorXPan;
		uint8_t mFloorYPan;

		uint8_t mVisibility;
		uint8_t mFillter;

		int16_t mLoTag;
		int16_t mHiTag;
		int16_t mExtra;
	};
	NoeCtAssert(sizeof(SMapSector) == 40);

	struct SMapWall
	{
		int32_t mPos[2];
		//note that terminology has been changed from BUILDINF.txt, because this makes a bit more sense to me.
		//mNextWall == "point2", mOtherWall == "nextwall", mOtherSector == "nextsector"
		int16_t mNextWall; //index of wall to right
		int16_t mOtherWall; //index to wall on other side of wall, -1 if there is no sector
		int16_t mOtherSector; //index to sector on other side of wall, -1 if there is no sector
		int16_t mCStat;

		int16_t mPicIndex;
		int16_t mOverPicIndex;

		int8_t mShade;
		uint8_t mPal;

		uint8_t mXRepeat;
		uint8_t mYRepeat;
		uint8_t mXPan;
		uint8_t mYPan;

		int16_t mLoTag;
		int16_t mHiTag;
		int16_t mExtra;
	};
	NoeCtAssert(sizeof(SMapWall) == 32);

	struct SMapSprite
	{
		int32_t mPos[3];
		int16_t mCStat;

		int16_t mPicIndex;

		int8_t mShade;
		uint8_t mPal;

		uint8_t mClipDist;
		uint8_t mFiller;

		uint8_t mXRepeat;
		uint8_t mYRepeat;
		int8_t mXOffset;
		int8_t mYOffset;

		int16_t mSectorIndex;
		int16_t mStatNum;

		int16_t mAngle;
		int16_t mOwner;
		int16_t mVel[3];

		int16_t mLoTag;
		int16_t mHiTag;
		int16_t mExtra;
	};
	NoeCtAssert(sizeof(SMapSprite) == 44);

	struct SMapInfo
	{
		uint32_t mSectorCount;
		const SMapSector *mpSectors;

		uint32_t mWallCount;
		const SMapWall *mpWalls;

		uint32_t mSpriteCount;
		const SMapSprite *mpSprites;
	};

	enum ESectorCStatBits
	{
		kSecCStat_Parallaxing = (1 << 0),
		kSecCStat_Sloped = (1 << 1),
		kSecCStat_SwapXY = (1 << 2),
		kSecCStat_DoubleSmooshiness = (1 << 3),
		kSecCStat_XFlip = (1 << 4),
		kSecCStat_YFlip = (1 << 5),
		kSecCStat_AlignToFirstWall = (1 << 6)
	};

	enum EWallCStatBits
	{
		kWallCStat_Blocking = (1 << 0),
		kWallCStat_InvisibleBottomsSwapped = (1 << 1),
		kWallCStat_AlignOnBottom = (1 << 2),
		kWallCStat_XFlip = (1 << 3),
		kWallCStat_Masking = (1 << 4),
		kWallCStat_OneWay = (1 << 5),
		kWallCStat_BlockingHitscan = (1 << 6),
		kWallCStat_Translucence = (1 << 7),
		kWallCStat_YFlip = (1 << 8),
		kWallCStat_TranslucenceReversing = (1 << 9)
	};

	enum ESpriteCStatBits
	{
		kSprCStat_Blocking = (1 << 0),
		kSprCStat_Translucence = (1 << 1),
		kSprCStat_XFlip = (1 << 2),
		kSprCStat_YFlip = (1 << 3),
		kSprCStat_FaceOffset = 4,
		kSprCStat_FaceMask = (3 << kSprCStat_FaceOffset),
		kSprCStat_OneSided = (1 << 6),
		kSprCStat_Centered = (1 << 7),
		kSprCStat_BlockingHitscan = (1 << 8),
		kSprCStat_TranslucenceReversing = (1 << 9),
		kSprCStat_Invisible = (1 << 15)
	};

	enum ESpriteFaceType
	{
		kSpriteFace_Facing = 0,
		kSpriteFace_Wall = 1,
		kSpriteFace_Floor = 2
	};

	enum ESpriteMode
	{
		kSpriteMode_NonEffectors = 0,
		kSpriteMode_All = 1,
		kSpriteMode_None = 2
	};

	struct SPerSectorData
	{
		RichPoly2D::TPolyShapes mConcaveShapes;
		RichPoly2D::TPolyShapesList mConvexShapes;

		TMapSectorInfoList mSectorInfos;
	};
	typedef std::vector<SPerSectorData> TPerSectorDataList;

	struct SArtTileHeader
	{
		int32_t mVersion;
		int32_t mTileCount; //BUILDINF.txt recommends not trusting this
		int32_t mTileStartNumber;
		int32_t mTileEndNumber;
	};

	class CArtTileFile
	{
	public:
		enum ETileAnimType
		{
			skTileAnimType_NoAnimation = 0,
			skTileAnimType_AnimOscillating,
			skTileAnimType_AnimForward,
			skTileAnimType_AnimBackward
		};

		//8 bits are reserved for texture flags
		enum ETextureFlags
		{
			skTextureFlags_None = 0,
			skTextureFlags_AlignHeight = (1 << 0) //convenient workaround for Build wall addressing
		};

		CArtTileFile(const wchar_t *pFilename, const int32_t fileIndex, noeRAPI_t *pRapi)
			: mValid(false)
			, mFileIndex(fileIndex)
			, mpRapi(pRapi)
			, mFile(pFilename, NOEFSMODE_READBINARY, pRapi)
			, mpTileWidths(NULL)
			, mpTileHeights(NULL)
			, mpTileBits(NULL)
			, mpTileOffsets(NULL)
		{
			mValid = mFile.IsValid();
			if (mValid)
			{
				mValid = ParseArtFile();
			}
		}

		~CArtTileFile()
		{
			if (mpTileWidths)
			{
				mpRapi->Noesis_UnpooledFree(mpTileWidths);
			}
		}

		bool IsValid() const
		{
			return mValid;
		}

		bool ContainsTile(const int32_t tileIndex) const
		{
			return (tileIndex >= mHeader.mTileStartNumber && tileIndex <= mHeader.mTileEndNumber);
		}

		void GetTileXYOffsets(int8_t *pXOffset, int8_t *pYOffset, const int32_t tileIndex) const
		{
			NoeAssert(tileIndex >= mHeader.mTileStartNumber && tileIndex <= mHeader.mTileEndNumber);
			const int32_t localTileIndex = tileIndex - mHeader.mTileStartNumber;
			const uint32_t tileInfo = mpTileBits[localTileIndex];
			*pXOffset = (tileInfo & skTileInfo_XCenterMask) >> skTileInfo_XCenterOffset;
			*pYOffset = (tileInfo & skTileInfo_YCenterMask) >> skTileInfo_YCenterOffset;
		}

		bool GetAnimatedTileInfo(uint32_t *pAnimTypeOut, uint32_t *pAnimCountOut, uint32_t *pAnimSpeedOut, const int32_t tileIndex) const
		{
			NoeAssert(tileIndex >= mHeader.mTileStartNumber && tileIndex <= mHeader.mTileEndNumber);
			const int32_t localTileIndex = tileIndex - mHeader.mTileStartNumber;
			const uint32_t tileInfo = mpTileBits[localTileIndex];
			const uint32_t animType = (tileInfo & skTileInfo_AnimTypeMask) >> skTileInfo_AnimTypeOffset;
			if (animType)
			{
				*pAnimTypeOut = animType;
				*pAnimCountOut = (tileInfo & skTileInfo_AnimCountMask) + 1;
				*pAnimSpeedOut = ((tileInfo & skTileInfo_AnimSpeedMask) >> skTileInfo_AnimSpeedOffset);
				return true;
			}
			return false;
		}

		noesisTex_t *LoadTileWithPalette(const int32_t tileIndex, const uint8_t *pPalData, const uint8_t *pShadingTable, const uint8_t textureFlags, const int32_t textureIndex)
		{
			NoeAssert(tileIndex >= mHeader.mTileStartNumber && tileIndex <= mHeader.mTileEndNumber);
			const int32_t localTileIndex = tileIndex - mHeader.mTileStartNumber;
			const uint32_t w = mpTileWidths[localTileIndex];
			const uint32_t h = mpTileHeights[localTileIndex];
			const uint32_t ofs = mpTileOffsets[localTileIndex];

			char textureName[MAX_NOESIS_PATH];
			sprintf_s(textureName, "art%03i_tile%03i_%i", mFileIndex, localTileIndex, textureIndex);

			if (w == 0 || h == 0)
			{
				return mpRapi->Noesis_AllocPlaceholderTex(textureName, 4, 4, false);
			}

			const uint32_t actualHeight = (textureFlags & skTextureFlags_AlignHeight) ? g_mfn->Math_NextPow2(h) : h;
			uint8_t *pPixelData = (uint8_t *)mpRapi->Noesis_UnpooledAlloc(w * actualHeight);
			mFile.Seek(ofs, false);
			mFile.Read(pPixelData, w * actualHeight);

			uint8_t *pRgba = (uint8_t *)mpRapi->Noesis_UnpooledAlloc(w * actualHeight * 4);
			for (uint32_t y = 0; y < actualHeight; ++y)
			{
				const uint32_t wrappedY = y % h;
				for (uint32_t x = 0; x < w; ++x)
				{
					const uint32_t destPixelIndex = y * w + x;
					uint32_t palIndex = pPixelData[wrappedY + x * h];
					if (palIndex != 255)
					{
						if (pShadingTable)
						{ //optionally remap the palette index if we have a shading table
							palIndex = pShadingTable[palIndex];
						}
						pRgba[destPixelIndex * 4 + 0] = pPalData[palIndex * 3 + 0];
						pRgba[destPixelIndex * 4 + 1] = pPalData[palIndex * 3 + 1];
						pRgba[destPixelIndex * 4 + 2] = pPalData[palIndex * 3 + 2];
						pRgba[destPixelIndex * 4 + 3] = 255;
					}
					else
					{
						pRgba[destPixelIndex * 4 + 0] = 0;
						pRgba[destPixelIndex * 4 + 1] = 0;
						pRgba[destPixelIndex * 4 + 2] = 0;
						pRgba[destPixelIndex * 4 + 3] = 0;
					}
				}
			}

			mpRapi->Noesis_UnpooledFree(pPixelData);

			noesisTex_t *pNoeTex = mpRapi->Noesis_TextureAlloc(textureName, w, actualHeight, pRgba, NOESISTEX_RGBA32);
			//useful for comparing texcoords with Build
			//pNoeTex->flags |= NTEXFLAG_FILTER_NEAREST;
			pNoeTex->shouldFreeData = true;

			return pNoeTex;
		}

	private:
		enum ETileInfoBits
		{
			skTileInfo_AnimCountMask = 63,
			skTileInfo_AnimTypeOffset = 6,
			skTileInfo_AnimTypeMask = (3 << skTileInfo_AnimTypeOffset),
			skTileInfo_XCenterOffset = 8,
			skTileInfo_XCenterMask = (255 << skTileInfo_XCenterOffset),
			skTileInfo_YCenterOffset = 16,
			skTileInfo_YCenterMask = (255 << skTileInfo_YCenterOffset),
			skTileInfo_AnimSpeedOffset = 24,
			skTileInfo_AnimSpeedMask = (15 << skTileInfo_AnimSpeedOffset)
		};

		bool ParseArtFile()
		{
			mFile.Seek(0, false);
			mFile.Read(&mHeader, sizeof(mHeader));
			if (mHeader.mVersion != 1)
			{
				return false;
			}

			mTileCount = mHeader.mTileEndNumber - mHeader.mTileStartNumber + 1;
			if (mTileCount <= 0)
			{
				return false;
			}

			uint8_t *pTileMem = (uint8_t *)mpRapi->Noesis_UnpooledAlloc(sizeof(uint16_t) * mTileCount * 2 + sizeof(uint32_t) * mTileCount * 2);
			mpTileWidths = (uint16_t *)pTileMem;
			mpTileHeights = mpTileWidths + mTileCount;
			mpTileBits = (uint32_t *)(mpTileHeights + mTileCount);
			mpTileOffsets = (uint32_t *)(mpTileBits + mTileCount);

			mFile.Read(mpTileWidths, sizeof(uint16_t) * mTileCount);
			mFile.Read(mpTileHeights, sizeof(uint16_t) * mTileCount);
			mFile.Read(mpTileBits, sizeof(uint32_t) * mTileCount);

			uint32_t currentOffset = (uint32_t)mFile.Tell();
			for (int32_t tileIndex = 0; tileIndex < mTileCount; ++tileIndex)
			{
				mpTileOffsets[tileIndex] = currentOffset;
				currentOffset += mpTileWidths[tileIndex] * mpTileHeights[tileIndex];
			}

			return true;
		}

		RichFileWrap mFile;
		noeRAPI_t *mpRapi;

		int32_t mFileIndex;
		bool mValid;

		SArtTileHeader mHeader;
		int32_t mTileCount;

		uint16_t *mpTileWidths;
		uint16_t *mpTileHeights;
		uint32_t *mpTileBits;
		uint32_t *mpTileOffsets;
	};

	class CArtTileData
	{
	public:
		//16 bits are reserved for material flags in the material map
		enum EMaterialFlags
		{
			skMaterialFlags_None = 0,
			skMaterialFlags_Translucence = (1 << 0),
			skMaterialFlags_TwoSided = (1 << 1),
			skMaterialFlags_FacingSprite = (1 << 2)
		};

		CArtTileData(noeRAPI_t *pRapi)
			: mpRapi(pRapi)
		{
			wchar_t basePath[MAX_NOESIS_PATH];
			pRapi->Noesis_GetDirForFilePathW(basePath, pRapi->Noesis_GetLastCheckedNameW());

			wchar_t artPath[MAX_NOESIS_PATH];
			for (uint32_t artFileIndex = 0; artFileIndex < skMaxArtFileCount; ++artFileIndex)
			{
				swprintf_s(artPath, L"%sTILES%03i.ART", basePath, artFileIndex);
				CArtTileFile *pArtFile = new CArtTileFile(artPath, artFileIndex, pRapi);
				if (!pArtFile->IsValid())
				{
					delete pArtFile;
					break;
				}
				mArtFiles.push_back(pArtFile);
			}

			mpShadingTables = NULL;
			mShadingTableCount = 0;

			//attempt to load a palette
			swprintf_s(artPath, L"%sPALETTE.DAT", basePath);
			mpPalFileData = pRapi->Noesis_ReadFileW(artPath, &mPalFileDataSize);
			if (!mpPalFileData)
			{
				mPalFileDataSize = 0;
				//default palette data
				pRapi->LogOutput("WARNING: Could not locate PALETTE.DAT, no color data available.\n");
				mPalDataSize = skSinglePaletteSize;
				mpPalData = (uint8_t *)pRapi->Noesis_UnpooledAlloc(mPalDataSize);
				for (uint32_t palIndex = 0; palIndex < skSinglePaletteEntryCount; ++palIndex)
				{
					uint8_t *pPalEntry = mpPalData + palIndex * skSinglePaletteChannelCount;
					for (uint32_t channelIndex = 0; channelIndex < skSinglePaletteChannelCount; ++channelIndex)
					{
						pPalEntry[channelIndex] = (uint8_t)palIndex;
					}
				}
			}
			else
			{
				//first see if we can get at the shading table
				const int32_t shadingTableOffset = skSinglePaletteSize + sizeof(uint16_t);
				if (mPalFileDataSize > shadingTableOffset)
				{
					mShadingTableCount = *(uint16_t *)(mpPalFileData + skSinglePaletteSize);
					if (mShadingTableCount > 0)
					{
						const int32_t shadingTableEnd = shadingTableOffset + skSingleShadingTableSize * mShadingTableCount;
						if (shadingTableEnd <= mPalFileDataSize)
						{
							mpShadingTables = mpPalFileData + shadingTableOffset;
						}
						else
						{
							mpShadingTables = NULL;
							pRapi->LogOutput("WARNING: PALETTE.DAT is not large enough to contain the complete shading table.\n");
						}
					}
				}

				//next see if there's a LOOKUP.DAT, or if we should just live with a single palette.
				swprintf_s(artPath, L"%sLOOKUP.DAT", basePath);
				int32_t lookupFileSize;
				uint8_t *pLookupData = pRapi->Noesis_ReadFileW(artPath, &lookupFileSize);
				if (pLookupData)
				{
					RichBitStreamEx lookupBs(pLookupData, lookupFileSize);
					const uint32_t lookupDataCount = lookupBs.ReadByte();

					const uint32_t remainingLookupSize = lookupFileSize - (lookupBs.GetOffset() + lookupDataCount * 257);
					const uint32_t remainingPalCount = remainingLookupSize / skSinglePaletteSize;
					const uint32_t totalPalCount = 1 + lookupDataCount + remainingPalCount;

					mPalDataSize = skSinglePaletteSize * totalPalCount;
					mpPalData = (uint8_t *)pRapi->Noesis_UnpooledAlloc(mPalDataSize);

					//copy the default palette
					memcpy(mpPalData, mpPalFileData, mPalDataSize);

					//generate the color-swap palettes
					for (uint32_t lookupIndex = 0; lookupIndex < lookupDataCount; ++lookupIndex)
					{
						const uint32_t lookupRealIndex = lookupBs.ReadByte();
						NoeAssert(lookupRealIndex >= 1 && lookupRealIndex <= lookupDataCount); //index is 1-based, after default palette
						const uint8_t *pLookupData = (const uint8_t *)lookupBs.GetBuffer() + lookupBs.GetOffset();
						lookupBs.Seek(256);
						uint8_t *pPalDest = mpPalData + lookupRealIndex * skSinglePaletteSize;

						for (uint32_t entryIndex = 0; entryIndex < 256; ++entryIndex)
						{
							const uint8_t *pPalSource = mpPalData + (uint32_t)pLookupData[entryIndex] * 3;
							pPalDest[entryIndex * 3 + 0] = pPalSource[0];
							pPalDest[entryIndex * 3 + 1] = pPalSource[1];
							pPalDest[entryIndex * 3 + 2] = pPalSource[2];
						}
					}
					
					//tack the remaining palettes onto the end
					memcpy(mpPalData + (1 + lookupDataCount) * skSinglePaletteSize, lookupBs.GetBuffer(), remainingLookupSize);

					pRapi->Noesis_UnpooledFree(pLookupData);
				}
				else
				{
					pRapi->LogOutput("WARNING: Could not locate LOOKUP.DAT, only one palette will be available.\n");
					//couldn't find lookup data, so we'll only use 1 palette
					mPalDataSize = skSinglePaletteSize;
					mpPalData = (uint8_t *)pRapi->Noesis_UnpooledAlloc(mPalDataSize);
					memcpy(mpPalData, mpPalFileData, mPalDataSize);
				}

				//expand colors to 8 bits
				for (int32_t palOffset = 0; palOffset < mPalDataSize; ++palOffset)
				{
					uint8_t c = mpPalData[palOffset];
					mpPalData[palOffset] = (c << 2) | (c >> 4);
				}
			}
			mPalCount = mPalDataSize / skSinglePaletteSize;
		}

		~CArtTileData()
		{
			for (TArtTileFileList::iterator it = mArtFiles.begin(); it != mArtFiles.end(); ++it)
			{
				delete *it;
			}
			mpRapi->Noesis_UnpooledFree(mpPalData);
			if (mpPalFileData)
			{
				mpRapi->Noesis_UnpooledFree(mpPalFileData);
			}
		}

		noesisTex_t *TextureForMaterial(const noesisMaterial_t *pNoeMat) const
		{
			if (!pNoeMat || pNoeMat->texIdx < 0 || pNoeMat->texIdx >= mNoesisTextures.Num())
			{
				return NULL;
			}
			return mNoesisTextures[pNoeMat->texIdx];
		}

		noesisMaterial_t *MaterialForTile(const uint16_t tileIndex, const uint16_t palIndex, const int8_t shadingTableIndex, const uint8_t textureFlags, const uint16_t materialFlags)
		{
			const uint64_t tileKey = GetTileIndexKey(tileIndex, palIndex, shadingTableIndex, textureFlags, materialFlags);
			TTileMaterialMap::iterator materialIt = mTileMaterialMap.find(tileKey);
			if (materialIt != mTileMaterialMap.end())
			{
				return mNoesisMaterials[materialIt->second];
			}

			if (materialFlags != skMaterialFlags_None)
			{
				//if we have material flags, create the base material/texture without flags, then modify the new material as desired while pointing it at the shared texture.
				noesisMaterial_t *pBaseMaterial = MaterialForTile(tileIndex, palIndex, shadingTableIndex, textureFlags, 0);
				if (pBaseMaterial)
				{
					const uint32_t noeMatIndex = CreateDefaultMaterial(pBaseMaterial->texIdx);
					mTileMaterialMap[tileKey] = noeMatIndex;

					noesisMaterial_t *pNoeMat = mNoesisMaterials[noeMatIndex];
					if (materialFlags & skMaterialFlags_Translucence)
					{
						pNoeMat->blendSrc = NOEBLEND_SRC_ALPHA;
						pNoeMat->blendDst = NOEBLEND_ONE_MINUS_SRC_ALPHA;
						pNoeMat->diffuse[0] = 1.0f;
						pNoeMat->diffuse[1] = 1.0f;
						pNoeMat->diffuse[2] = 1.0f;
						pNoeMat->diffuse[3] = 0.5f;
					}
					if (materialFlags & skMaterialFlags_TwoSided)
					{
						pNoeMat->flags |= NMATFLAG_TWOSIDED;
					}
					if (materialFlags & skMaterialFlags_FacingSprite)
					{
						pNoeMat->flags |= NMATFLAG_SPRITE_FACINGXY;
					}
					//we can safely point to the base material's expressions, as expressions are pool-allocated.
					pNoeMat->expr = pBaseMaterial->expr;

					return pNoeMat;
				}
			}
			else
			{
				//if it didn't already exist, we need to create it
				for (TArtTileFileList::iterator it = mArtFiles.begin(); it != mArtFiles.end(); ++it)
				{
					CArtTileFile *pArtFile = *it;
					if (pArtFile->ContainsTile(tileIndex))
					{
						const uint8_t *pPalData = mpPalData + std::min<uint32_t>(palIndex, mPalCount - 1) * skSinglePaletteSize;
						const uint8_t *pShadingTable = GetShadingTable(shadingTableIndex);
						const uint32_t noeTexIndex = mNoesisTextures.Num();
						noesisTex_t *pNoeTex = pArtFile->LoadTileWithPalette(tileIndex, pPalData, pShadingTable, textureFlags, noeTexIndex);
						NoeAssert(pNoeTex);
						mNoesisTextures.Append(pNoeTex);

						const uint32_t noeMatIndex = CreateDefaultMaterial(noeTexIndex);
						mTileMaterialMap[tileKey] = noeMatIndex;

						noesisMaterial_t *pNoeMat = mNoesisMaterials[noeMatIndex];

						uint32_t animType, animCount, animSpeed;
						//load sequential animation tiles if they're present
						if (tileIndex > 0 && pArtFile->GetAnimatedTileInfo(&animType, &animCount, &animSpeed, tileIndex))
						{
							for (uint32_t animTileIndex = 0; animTileIndex < animCount; ++animTileIndex)
							{
								noesisTex_t *pNoeTex = pArtFile->LoadTileWithPalette(tileIndex + 1 + animTileIndex, pPalData, pShadingTable, textureFlags, noeTexIndex + 1 + animTileIndex);
								NoeAssert(pNoeTex);
								mNoesisTextures.Append(pNoeTex);
							}

							//Build shifts the current clock right by animSpeed.
							const float buildTimeScale = 1.0f / (1 << animSpeed);
							//now scale from Build ticks to milliseconds at default duke3d tick rate (120 / 26 ticks per frame at 30hz timing)
							const float buildTicksPerSecond = 120.0f / 26.0f * 30.0f;
							const float animTimeScale = buildTimeScale * buildTicksPerSecond / 1000.0f;
							//create a material expression to animate the texture
							pNoeMat->expr = mpRapi->Noesis_AllocMaterialExpressions(NULL);
							char texExpr[MAX_NOESIS_PATH];
							switch (animType)
							{
							case CArtTileFile::skTileAnimType_AnimOscillating:
								//oscillate on a triangle wave (not quite what Build does, and avoids doubling up on frames at either end)
								sprintf(texExpr, "%i + (abs(mod(time * %f, 2.0) - 1.0) * %i", noeTexIndex, animTimeScale * 0.25f, animCount);
								break;
							case CArtTileFile::skTileAnimType_AnimBackward:
								sprintf(texExpr, "%i - mod(time * %f, %i)", noeTexIndex + animCount, animTimeScale, animCount);
								break;
							case CArtTileFile::skTileAnimType_AnimForward:
							default:
								sprintf(texExpr, "%i + mod(time * %f, %i)", noeTexIndex, animTimeScale, animCount);
								break;
							}
							pNoeMat->expr->texIdx = mpRapi->Express_Parse(texExpr);
						}

						return pNoeMat;
					}
				}
			}

			return NULL;
		}

		void GetTileXYOffsets(int8_t *pXOffset, int8_t *pYOffset, const int32_t tileIndex) const
		{
			for (TArtTileFileList::const_iterator it = mArtFiles.begin(); it != mArtFiles.end(); ++it)
			{
				const CArtTileFile *pArtFile = *it;
				if (pArtFile->ContainsTile(tileIndex))
				{
					pArtFile->GetTileXYOffsets(pXOffset, pYOffset, tileIndex);
					return;
				}
			}
			*pXOffset = 0;
			*pYOffset = 0;
		}

		noesisMatData_t *CreateNoesisMaterialData()
		{
			if (mNoesisMaterials.Num() <= 0)
			{
				return NULL;
			}

			return mpRapi->Noesis_GetMatDataFromLists(mNoesisMaterials, mNoesisTextures);
		}

		//many modern api's and/or vendor implementations don't natively support paletted textures, so if we want to support shading tables
		//the Build Engine way via rgba32 textures, that means lots of duplicating textures with remapped shading. so we default to just
		//approximating shading via vertex colors.
		bool UseShadingTables() const
		{
			return g_buildMapOpts->mUseShadingTables && mpShadingTables != NULL;
		}

	private:
		typedef std::vector<CArtTileFile *> TArtTileFileList;
		typedef std::map<uint64_t, uint32_t> TTileMaterialMap;

		uint64_t GetTileIndexKey(const uint16_t tileIndex, const uint16_t palIndex, const int8_t shadingTableIndex, const uint8_t textureFlags, const uint16_t materialFlags) const
		{
			uint64_t tileKey = (uint64_t)tileIndex | ((uint64_t)palIndex << 16ULL) | ((uint64_t)textureFlags << 32ULL) | ((uint64_t)materialFlags << 40ULL);
			if (UseShadingTables())
			{
				tileKey |= ((uint64_t)std::max<int8_t>(shadingTableIndex, 0) << 56ULL);
			}
			return tileKey;
		}

		const uint8_t *GetShadingTable(const int8_t shadingTableIndex) const
		{
			if (!UseShadingTables())
			{
				return NULL;
			}
			const int32_t clampedIndex = std::min<int32_t>(std::max<int32_t>(shadingTableIndex, 0), mShadingTableCount - 1);
			return mpShadingTables + clampedIndex * skSingleShadingTableSize;
		}

		uint32_t CreateDefaultMaterial(const int32_t textureIndex)
		{
			const uint32_t noeMatIndex = mNoesisMaterials.Num();
			noesisMaterial_t *pNoeMat = mpRapi->Noesis_GetMaterialList(1, false);

			char materialName[MAX_NOESIS_PATH];
			sprintf_s(materialName, "material%04i", noeMatIndex);
			pNoeMat->name = mpRapi->Noesis_PooledString(materialName);
			pNoeMat->texIdx = textureIndex;
			pNoeMat->noLighting = true;

			mNoesisMaterials.Append(pNoeMat);

			return noeMatIndex;
		}

		noeRAPI_t *mpRapi;

		TArtTileFileList mArtFiles;

		//a variable number of palettes may be present if generated from lookup.dat
		uint8_t *mpPalData;
		int32_t mPalDataSize;
		int32_t mPalCount;

		//original palette.dat data
		uint8_t *mpPalFileData;
		int32_t mPalFileDataSize;

		//pointer into mpPalFileData, if shading table data is present. otherwise NULL;
		uint8_t *mpShadingTables;
		int32_t mShadingTableCount;

		CArrayList<noesisTex_t *> mNoesisTextures;
		CArrayList<noesisMaterial_t *> mNoesisMaterials;

		TTileMaterialMap mTileMaterialMap;
	};

	bool get_map_info(SMapInfo *pInfo, const uint8_t *pBuffer, const int32_t bufferLen)
	{
		if (bufferLen < (sizeof(SMapHeader) + sizeof(uint16_t)))
		{
			return false;
		}

		const SMapHeader *pHdr = (const SMapHeader *)pBuffer;
		if (pHdr->mVersion != 7)
		{
			return false;
		}

		int32_t ofs = sizeof(SMapHeader);
		pInfo->mSectorCount = *(const uint16_t *)(pBuffer + ofs);
		ofs += sizeof(uint16_t);
		pInfo->mpSectors = (const SMapSector *)(pBuffer + ofs);
		ofs += sizeof(SMapSector) * pInfo->mSectorCount;
		if (ofs <= 0 || (ofs + (int32_t)sizeof(uint16_t)) >= bufferLen)
		{
			return false;
		}

		pInfo->mWallCount = *(const uint16_t *)(pBuffer + ofs);
		ofs += sizeof(uint16_t);
		pInfo->mpWalls = (const SMapWall *)(pBuffer + ofs);
		ofs += sizeof(SMapWall) * pInfo->mWallCount;
		if (ofs <= 0 || (ofs + (int32_t)sizeof(uint16_t)) >= bufferLen)
		{
			return false;
		}

		pInfo->mSpriteCount = *(const uint16_t *)(pBuffer + ofs);
		ofs += sizeof(uint16_t);
		pInfo->mpSprites = (const SMapSprite *)(pBuffer + ofs);
		ofs += sizeof(SMapSprite) * pInfo->mSpriteCount;
		if (ofs != bufferLen)
		{ //require an exact match, just because .map is a pretty generic extension and the format doesn't include any particularly good identifiers
			return false;
		}

		return true;
	}

	RichVecH2 get_xy_coord(const int32_t *pXyCoord)
	{
		return RichVecH2(-(double)pXyCoord[0], (double)pXyCoord[1]);
	}

	double get_z_coord(const int32_t zCoord)
	{
		return -(double)zCoord / 16.0; //BUILDINF.txt notes all z coords are shifted up (left) by 4
	}

	//written by observing Build source's getceilzofslope (math is identical for floor and ceiling)
	double get_slope_z(const SMapInfo &info, const SMapSector *pSector, const double posX, const double posY, const double baseZ, const double slopeValue)
	{
		const SMapWall *pWall = info.mpWalls + pSector->mWallIndex;
		const SMapWall *pNextWall = info.mpWalls + pWall->mNextWall;

		const RichVecH2 wallPos = get_xy_coord(pWall->mPos);
		const RichVecH2 nextWallPos = get_xy_coord(pNextWall->mPos);
		const RichVecH2 dxy = nextWallPos - wallPos;

		const double dxyLength = dxy.Length() * 32.0;
		if (dxyLength == 0.0)
		{
			return baseZ;
		}
		const double cx = (dxy[0] * (posY - wallPos[1]) + -dxy[1] * (posX - wallPos[0])) / 8.0;
		return baseZ + slopeValue * cx / dxyLength / 16.0;
	}

	double get_sloped_floor_z(const SMapInfo &info, const SMapSector *pSector, const double posX, const double posY)
	{
		//ignore slope value unless sloped bit is set
		if (!(pSector->mFloorStat & kSecCStat_Sloped))
		{
			return get_z_coord(pSector->mFloorZ);
		}

		return get_slope_z(info, pSector, posX, posY, get_z_coord(pSector->mFloorZ), pSector->mFloorHeiNum);
	}

	double get_sloped_ceiling_z(const SMapInfo &info, const SMapSector *pSector, const double posX, const double posY)
	{
		//ignore slope value unless sloped bit is set
		if (!(pSector->mCeilStat & kSecCStat_Sloped))
		{
			return get_z_coord(pSector->mCeilingZ);
		}

		return get_slope_z(info, pSector, posX, posY, get_z_coord(pSector->mCeilingZ), pSector->mCeilingHeiNum);
	}

	//if not handling this "correctly", we just produce a linearly scaled color instead, based upon an expected 32 entries in the shading table.
	RichVec4 approximate_color_for_shading_entry(int32_t shadeIndex)
	{
		const float intensity = (31 - std::min<int32_t>(std::max<int32_t>(shadeIndex, 0), 31)) / 31.0f;
		return RichVec4(intensity, intensity, intensity, 1.0f);
	}

	RichVec3 get_sector_draw_vert(const SMapInfo &info, const RichVecH2 &pos, const SMapSector *pSector, const bool onCeiling)
	{
		return RichVec3((float)pos[0], (float)pos[1],
			(onCeiling) ? (float)get_sloped_ceiling_z(info, pSector, pos[0], pos[1]) : (float)get_sloped_floor_z(info, pSector, pos[0], pos[1]));
	}

	RichVec2 get_sector_draw_uv(const SMapInfo &info, const CArtTileData &artTileData, const RichVecH2 &pos, const SMapSector *pSector, const noesisMaterial_t *pMaterial, const bool onCeiling)
	{
		noesisTex_t *pTexture = artTileData.TextureForMaterial(pMaterial);
		if (!pTexture)
		{
			return RichVec2(0.0f, 0.0f);
		}

		const uint32_t cStat = (onCeiling) ? pSector->mCeilStat : pSector->mFloorStat;

		const double scaleFactor = (cStat & kSecCStat_DoubleSmooshiness) ? 8.0 : 16.0;
		const RichVecH2 toUVSpace = (RichVecH2((double)pTexture->w, (double)pTexture->h) * scaleFactor).InverseOrZero();

		RichVecH2 texPos = pos;

		//observing the order of these operations based on the Build source

		if (cStat & kSecCStat_AlignToFirstWall)
		{
			const SMapWall *pWall = info.mpWalls + pSector->mWallIndex;
			const SMapWall *pNextWall = info.mpWalls + pWall->mNextWall;

			const double slopeValue = (onCeiling) ? pSector->mCeilingHeiNum : pSector->mFloorHeiNum;

			const RichVecH2 wallPos = get_xy_coord(pWall->mPos);
			const RichVecH2 nextWallPos = get_xy_coord(pNextWall->mPos);

			const RichVecH2 dxy = (nextWallPos - wallPos).Normalized();
			const RichVecH2 xy = wallPos - texPos;
			//arbitrarily scale y as the slope angle diverges from 0, such that the maximum slope ends up scaling by around 8.
			const double slopeFourtyFiveDegrees = 4096.0;
			const double slopeFactor = sqrt(slopeValue * slopeValue + slopeFourtyFiveDegrees * slopeFourtyFiveDegrees) / slopeFourtyFiveDegrees;

			texPos = RichVecH2(xy[0] * dxy[0] + xy[1] * dxy[1], (-xy[1] * dxy[0] + xy[0] * dxy[1]) * slopeFactor);
		}

		if (cStat & kSecCStat_SwapXY)
		{
			const double tU = texPos[0];
			texPos[0] = texPos[1];
			texPos[1] = tU;
		}
		if (cStat & kSecCStat_XFlip)
		{
			texPos[0] = -texPos[0];
		}
		if (cStat & kSecCStat_YFlip)
		{
			texPos[1] = -texPos[1];
		}

		RichVecH2 uv = texPos * toUVSpace;

		const int32_t xPan = (onCeiling) ? pSector->mCeilingXPan : pSector->mFloorXPan;
		const int32_t yPan = (onCeiling) ? pSector->mCeilingYPan : pSector->mFloorYPan;
		uv -= RichVecH2((double)xPan / 256.0, (double)yPan / 256.0);

		return RichVec2(-(float)uv[0], -(float)uv[1]);
	}

	//expects v0 and v1 to be on the left side of the wall
	void calculate_wall_uvs(RichVec2 *pUVsOut, const SMapInfo &info, const CArtTileData &artTileData, const noesisMaterial_t *pMaterial,
	                        const uint32_t cStat, const uint8_t xPan, const uint8_t yPan, const SMapWall *pWall,
	                        const RichVec3 &v0, const RichVec3 &v1, const RichVec3 &v2, const RichVec3 &v3, const double heightBase)
	{
		noesisTex_t *pTexture = artTileData.TextureForMaterial(pMaterial);
		if (!pTexture)
		{
			pUVsOut[0] = RichVec2(0.0f, 0.0f);
			pUVsOut[1] = RichVec2(0.0f, 1.0f);
			pUVsOut[2] = RichVec2(1.0f, 1.0f);
			pUVsOut[3] = RichVec2(1.0f, 0.0f);
			return;
		}

		const SMapWall *pNextWall = info.mpWalls + pWall->mNextWall;
		const RichVecH2 wallPos = get_xy_coord(pWall->mPos);
		const RichVecH2 nextWallPos = get_xy_coord(pNextWall->mPos);

		const float segWidth = (float)(nextWallPos - wallPos).Length();
		const float xCoordLeft = (cStat & kWallCStat_XFlip) ? segWidth : 0.0f;
		const float xCoordRight = (cStat & kWallCStat_XFlip) ? 0.0f : segWidth;
		const float yCoordBase = (float)heightBase;
		const float yScale = (cStat & kWallCStat_YFlip) ? -1.0f : 1.0f;

		const float invXRepeat = (pWall->mXRepeat > 0) ? 1.0f / (float)pWall->mXRepeat : 0.0f;
		const float invYRepeat = (pWall->mYRepeat > 0) ? 1.0f / (float)pWall->mYRepeat : 0.0f;

		//more magic numbers derived from Build logic
		const float scaleFactor = 16.0f;
		const float xRepeat = (segWidth / 128.0f) * invXRepeat;
		const float yRepeat = 8.0f * invYRepeat;
		const RichVec2 toUVSpace = (RichVec2((float)pTexture->w * xRepeat, (float)pTexture->h * yRepeat) * scaleFactor).InverseOrZero();

		const RichVec2 uvPan((float)xPan / (float)pTexture->w, (float)yPan / 256.0f);

		pUVsOut[0] = RichVec2(xCoordLeft, (yCoordBase - v0[2]) * yScale) * toUVSpace + uvPan;
		pUVsOut[1] = RichVec2(xCoordLeft, (yCoordBase - v1[2]) * yScale) * toUVSpace + uvPan;
		pUVsOut[2] = RichVec2(xCoordRight, (yCoordBase - v2[2]) * yScale) * toUVSpace + uvPan;
		pUVsOut[3] = RichVec2(xCoordRight, (yCoordBase - v3[2]) * yScale) * toUVSpace + uvPan;
	}

	uint8_t texture_flags_for_wall()
	{
		return (g_buildMapOpts->mNoAlignTileHeight) ? CArtTileFile::skTextureFlags_None : CArtTileFile::skTextureFlags_AlignHeight;
	}

	uint16_t material_flags_for_wall(const int16_t cStat)
	{
		uint16_t materialFlags = CArtTileData::skMaterialFlags_None;
		if (cStat & kWallCStat_Translucence)
		{
			materialFlags |= CArtTileData::skMaterialFlags_Translucence;
		}
		return materialFlags;
	}

	void generate_sector_data(TPerSectorDataList &perSectorData, const SMapInfo &info, noeRAPI_t *pRapi)
	{
		perSectorData.resize(info.mSectorCount);

		typedef std::set<uint32_t> TTouchedWalls;
		TTouchedWalls touchedWalls;

		for (uint32_t sectorIndex = 0; sectorIndex < info.mSectorCount; ++sectorIndex)
		{
			const SMapSector *pSector = info.mpSectors + sectorIndex;
			SPerSectorData &sectorData = perSectorData[sectorIndex];

			for (int32_t wallIndex = 0; wallIndex < pSector->mWallCount; ++wallIndex)
			{
				const int32_t absWallIndex = pSector->mWallIndex + wallIndex;
				if (!touchedWalls.insert(absWallIndex).second)
				{
					continue;
				}

				RichPoly2D::TPolyShapes &sectorConcaveShapes = sectorData.mConcaveShapes;
				sectorConcaveShapes.push_back(RichPoly2D::TPolyPointList());
				RichPoly2D::TPolyPointList &sectorPoly = sectorConcaveShapes.back();

				bool closedShape = false;
				const SMapWall *pWall = info.mpWalls + absWallIndex;
				for (uint32_t attemptCount = 0; attemptCount < skMaxSectorWalkAttemptCount; ++attemptCount)
				{
					const RichVecH2 pos = get_xy_coord(pWall->mPos);
					sectorPoly.push_back(pos);

					NoeAssert(pWall->mNextWall >= 0 && (uint32_t)pWall->mNextWall < info.mWallCount);

					if (pWall->mNextWall == absWallIndex)
					{ //break out when we've closed the sector
						closedShape = true;
						break;
					}
					touchedWalls.insert(pWall->mNextWall);
					pWall = info.mpWalls + pWall->mNextWall;
				}

				if (closedShape)
				{
					const bool isCCW = (RichPoly2D::PolyClockwise(sectorPoly) == RichPoly2D::kPolyClockwiseResult_CCW);
					if (isCCW)
					{
						RichPoly2D::ReverseWinding(sectorPoly);
					}

					//this is pretty necessary for Build Engine maps, as there are quite a few concave polygons with totally degenerate edges in them,
					//including some situations where an edge segment will overlap back on a previous edge segment. this function also catches those
					//degenerate edge cases.
					RichPoly2D::RemoveRedundantShapeSegments(sectorPoly);

					//a few rare sectors in duke3d have overlapping collinear segments
					RichPoly2D::AdjustCollinearSegments(sectorPoly);

					SMapSectorInfo sectorInfo(isCCW);

					TMapSectorInfoList &sectorInfos = sectorData.mSectorInfos;
					sectorInfos.push_back(sectorInfo);
				}
				else
				{
					//never seen this happen, but just in case
					pRapi->LogOutput("WARNING: Sector %i contains an open shape.\n", sectorIndex);
					sectorConcaveShapes.erase(sectorConcaveShapes.end() - 1);
				}
			}
			touchedWalls.clear();
		}

		for (uint32_t sectorIndex = 0; sectorIndex < info.mSectorCount; ++sectorIndex)
		{
			const SMapSector *pSector = info.mpSectors + sectorIndex;
			SPerSectorData &sectorData = perSectorData[sectorIndex];
			const RichPoly2D::TPolyShapes &sectorConcaveShapes = sectorData.mConcaveShapes;
			TMapSectorInfoList &sectorInfos = sectorData.mSectorInfos;
			const uint32_t concaveShapeCount = sectorConcaveShapes.size();

			NoeAssert(sectorInfos.size() == concaveShapeCount);

			//first loop, generate convex shapes
			RichPoly2D::TPolyShapesList &sectorConvexShapes = sectorData.mConvexShapes;
			for (uint32_t concaveShapeIndex = 0; concaveShapeIndex < concaveShapeCount; ++concaveShapeIndex)
			{
				sectorConvexShapes.push_back(RichPoly2D::TPolyShapes());
				RichPoly2D::TPolyShapes &sectorShapes = sectorConvexShapes.back();

				const RichPoly2D::TPolyPointList &sectorPoly = sectorConcaveShapes[concaveShapeIndex];
				RichPoly2D::GenerateTrianglesFromPoly(sectorShapes, sectorPoly);

				RichPoly2D::TPolyShapes tempShapes;
				std::swap(tempShapes, sectorShapes);
				RichPoly2D::MergeConvexShapes(sectorShapes, tempShapes);
			}

			//second loop, clip convex shapes with any CCW shapes, and remerge convex shapes
			for (uint32_t concaveShapeIndex = 0; concaveShapeIndex < concaveShapeCount; ++concaveShapeIndex)
			{
				const SMapSectorInfo &sectorInfo = sectorInfos[concaveShapeIndex];
				if (sectorInfo.mIsCCW)
				{ //no need to clip CCW sectors
					continue;
				}

				RichPoly2D::TPolyShapes &sectorShapes = sectorConvexShapes[concaveShapeIndex];
				//cut shapes against any CCW shapes in the same sector
				bool anyClipping = false;
				for (uint32_t otherShapeIndex = 0; otherShapeIndex < concaveShapeCount; ++otherShapeIndex)
				{
					const SMapSectorInfo &sectorInfo = sectorInfos[otherShapeIndex];
					if (sectorInfo.mIsCCW)
					{
						RichPoly2D::TPolyShapes &otherShapes = sectorConvexShapes[otherShapeIndex];

						RichPoly2D::TPolyShapes clippedSubject;
						RichPoly2D::ClipConvexShapes(clippedSubject, otherShapes, sectorShapes, RichPoly2D::kClipType_ExcludeInnerClip);
						std::swap(sectorShapes, clippedSubject);

						anyClipping = true;
					}
				}

				if (anyClipping)
				{
					//go ahead and re-merge convex shapes if any clipping took place
					RichPoly2D::TPolyShapes tempShapes;
					std::swap(tempShapes, sectorShapes);
					RichPoly2D::MergeConvexShapes(sectorShapes, tempShapes);
				}
			}
		}
	}

	void draw_map_geometry(CArtTileData &artTileData, const TPerSectorDataList &perSectorData, const SMapInfo &info, noeRAPI_t *pRapi)
	{
		for (uint32_t sectorIndex = 0; sectorIndex < info.mSectorCount; ++sectorIndex)
		{
			const SMapSector *pSector = info.mpSectors + sectorIndex;
			const SPerSectorData &sectorData = perSectorData[sectorIndex];

			const RichPoly2D::TPolyShapesList &convexShapesList = sectorData.mConvexShapes;
			const uint32_t convexShapeListCount = convexShapesList.size();
			const TMapSectorInfoList &sectorInfos = sectorData.mSectorInfos;
			NoeAssert(sectorInfos.size() == convexShapeListCount);

			if (g_buildMapOpts->mNameSectors)
			{
				char sectorName[MAX_NOESIS_PATH];
				sprintf_s(sectorName, "_map_sector_%04i_", sectorIndex);
				pRapi->rpgSetName(sectorName);
			}

			const bool skipUpperSector = (g_buildMapOpts->mSkipParallax && (pSector->mCeilStat & kSecCStat_Parallaxing));
			const bool skipLowerSector = (g_buildMapOpts->mSkipParallax && (pSector->mFloorStat & kSecCStat_Parallaxing));

			for (uint32_t convexShapeListIndex = 0; convexShapeListIndex < convexShapeListCount; ++convexShapeListIndex)
			{
				const SMapSectorInfo &sectorInfo = sectorInfos[convexShapeListIndex];
				if (sectorInfo.mIsCCW)
				{ //don't draw CCW shapes
					continue;
				}

				const RichPoly2D::TPolyShapes &sectorShapes = convexShapesList[convexShapeListIndex];
				const noesisMaterial_t *pFloorMaterial = artTileData.MaterialForTile(pSector->mFloorPicIndex, pSector->mFloorPal, pSector->mFloorShade,
				                                                                     CArtTileFile::skTextureFlags_None, CArtTileData::skMaterialFlags_None);
				const noesisMaterial_t *pCeilingMaterial = artTileData.MaterialForTile(pSector->mCeilingPicIndex, pSector->mCeilingPal, pSector->mCeilingShade,
				                                                                     CArtTileFile::skTextureFlags_None, CArtTileData::skMaterialFlags_None);

				const uint32_t shapeCount = sectorShapes.size();
				for (uint32_t shapeIndex = 0; shapeIndex < shapeCount; ++shapeIndex)
				{
					const RichPoly2D::TPolyPointList &points = sectorShapes[shapeIndex];
					const uint32_t pointCount = points.size();

					if (!skipLowerSector)
					{
						pRapi->rpgSetMaterial((pFloorMaterial) ? pFloorMaterial->name : "defaultmaterial");

						//draw floor
						if (!artTileData.UseShadingTables())
						{
							pRapi->rpgVertColor4f(approximate_color_for_shading_entry(pSector->mFloorShade).v);
						}
						pRapi->rpgBegin(RPGEO_POLYGON);
						for (uint32_t pointIndex = 0; pointIndex < pointCount; ++pointIndex)
						{
							const RichVecH2 &pos = points[pointCount - pointIndex - 1];
							RichVec2 vertUV = get_sector_draw_uv(info, artTileData, pos, pSector, pFloorMaterial, false);
							pRapi->rpgVertUV2f(vertUV.v, 0);
							RichVec3 vertPos = get_sector_draw_vert(info, pos, pSector, false);
							pRapi->rpgVertex3f(vertPos.v);
						}
						pRapi->rpgEnd();
					}

					if (!skipUpperSector)
					{
						pRapi->rpgSetMaterial((pCeilingMaterial) ? pCeilingMaterial->name : "defaultmaterial");

						//draw ceiling
						if (!artTileData.UseShadingTables())
						{
							pRapi->rpgVertColor4f(approximate_color_for_shading_entry(pSector->mCeilingShade).v);
						}
						pRapi->rpgBegin(RPGEO_POLYGON);
						for (uint32_t pointIndex = 0; pointIndex < pointCount; ++pointIndex)
						{
							const RichVecH2 &pos = points[pointIndex];
							RichVec2 vertUV = get_sector_draw_uv(info, artTileData, pos, pSector, pCeilingMaterial, true);
							pRapi->rpgVertUV2f(vertUV.v, 0);
							RichVec3 vertPos = get_sector_draw_vert(info, pos, pSector, true);
							pRapi->rpgVertex3f(vertPos.v);
						}
						pRapi->rpgEnd();
					}
				}

				//now draw walls for the sector
				for (int32_t wallIndex = 0; wallIndex < pSector->mWallCount; ++wallIndex)
				{
					const int32_t absWallIndex = pSector->mWallIndex + wallIndex;
					const SMapWall *pWall = info.mpWalls + absWallIndex;
					const SMapWall *pNextWall = info.mpWalls + pWall->mNextWall;

					const RichVecH2 pos = get_xy_coord(pWall->mPos);
					const RichVecH2 nextPos = get_xy_coord(pNextWall->mPos);

					RichVec3 v0 = get_sector_draw_vert(info, pos, pSector, true);
					RichVec3 v1 = get_sector_draw_vert(info, nextPos, pSector, true);
					RichVec3 v2 = get_sector_draw_vert(info, nextPos, pSector, false);
					RichVec3 v3 = get_sector_draw_vert(info, pos, pSector, false);

					RichVec2 wallUVs[4];

					const noesisMaterial_t *pWallMaterial = artTileData.MaterialForTile(pWall->mPicIndex, pWall->mPal, pWall->mShade,
					                                                                    texture_flags_for_wall(), CArtTileData::skMaterialFlags_None);

					pRapi->rpgSetMaterial((pWallMaterial) ? pWallMaterial->name : "defaultmaterial");

					if (pWall->mOtherSector < 0)
					{ //just draw the wall straight-up
						if (!artTileData.UseShadingTables())
						{
							pRapi->rpgVertColor4f(approximate_color_for_shading_entry(pWall->mShade).v);
						}

						calculate_wall_uvs(wallUVs, info, artTileData, pWallMaterial, pWall->mCStat, pWall->mXPan, pWall->mYPan, pWall, v0, v3, v2, v1,
						                   (pWall->mCStat & kWallCStat_AlignOnBottom) ? get_z_coord(pSector->mFloorZ) : get_z_coord(pSector->mCeilingZ));

						pRapi->rpgBegin(RPGEO_POLYGON);
						pRapi->rpgVertUV2f(wallUVs[0].v, 0);
						pRapi->rpgVertex3f(v0.v);
						pRapi->rpgVertUV2f(wallUVs[1].v, 0);
						pRapi->rpgVertex3f(v3.v);
						pRapi->rpgVertUV2f(wallUVs[2].v, 0);
						pRapi->rpgVertex3f(v2.v);
						pRapi->rpgVertUV2f(wallUVs[3].v, 0);
						pRapi->rpgVertex3f(v1.v);
						pRapi->rpgEnd();
					}
					else
					{
						const SMapSector *pOtherSector = info.mpSectors + pWall->mOtherSector;
						RichVec3 otherV0 = get_sector_draw_vert(info, pos, pOtherSector, true);
						RichVec3 otherV1 = get_sector_draw_vert(info, nextPos, pOtherSector, true);
						RichVec3 otherV2 = get_sector_draw_vert(info, nextPos, pOtherSector, false);
						RichVec3 otherV3 = get_sector_draw_vert(info, pos, pOtherSector, false);

						const bool skipUpperWall = (g_buildMapOpts->mSkipParallax && (pOtherSector->mCeilStat & kSecCStat_Parallaxing));
						const bool skipLowerWall = (g_buildMapOpts->mSkipParallax && (pOtherSector->mFloorStat & kSecCStat_Parallaxing));

						//draw the upper bit
						if (!skipUpperWall && (otherV0[2] < v0[2] || otherV1[2] < v1[2]))
						{
							if (!artTileData.UseShadingTables())
							{
								pRapi->rpgVertColor4f(approximate_color_for_shading_entry(pWall->mShade).v);
							}

							calculate_wall_uvs(wallUVs, info, artTileData, pWallMaterial, pWall->mCStat, pWall->mXPan, pWall->mYPan, pWall, v0, otherV0, otherV1, v1,
							                   (pWall->mCStat & kWallCStat_AlignOnBottom) ? get_z_coord(pSector->mCeilingZ) : get_z_coord(pOtherSector->mCeilingZ));

							pRapi->rpgBegin(RPGEO_POLYGON);
							pRapi->rpgVertUV2f(wallUVs[0].v, 0);
							pRapi->rpgVertex3f(v0.v);
							pRapi->rpgVertUV2f(wallUVs[1].v, 0);
							pRapi->rpgVertex3f(otherV0.v);
							pRapi->rpgVertUV2f(wallUVs[2].v, 0);
							pRapi->rpgVertex3f(otherV1.v);
							pRapi->rpgVertUV2f(wallUVs[3].v, 0);
							pRapi->rpgVertex3f(v1.v);
							pRapi->rpgEnd();
						}

						//draw the lower bit
						if (!skipLowerWall && (otherV2[2] > v2[2] || otherV3[2] > v3[2]))
						{
							int8_t bottomShade = pWall->mShade;
							uint32_t bottomCStat = pWall->mCStat;
							uint8_t bottomXPan = pWall->mXPan;
							uint8_t bottomYPan = pWall->mYPan;
							const noesisMaterial_t *pBottomMaterial = pWallMaterial;

							if ((pWall->mCStat & kWallCStat_InvisibleBottomsSwapped) && pWall->mOtherWall >= 0)
							{
								const SMapWall *pOtherWall = info.mpWalls + pWall->mOtherWall;
								bottomShade = pOtherWall->mShade;
								bottomCStat = pOtherWall->mCStat;
								bottomXPan = pOtherWall->mXPan;
								bottomYPan = pOtherWall->mYPan;
								//Build manages to check the original wall's cstat for x-flip, but not y-flip. ahh, Build.
								bottomCStat = (bottomCStat & ~kWallCStat_XFlip) | (pWall->mCStat & kWallCStat_XFlip);
								pBottomMaterial = artTileData.MaterialForTile(pOtherWall->mPicIndex, pOtherWall->mPal, bottomShade,
								                                              texture_flags_for_wall(), CArtTileData::skMaterialFlags_None);

								pRapi->rpgSetMaterial((pBottomMaterial) ? pBottomMaterial->name : "defaultmaterial");
							}

							if (!artTileData.UseShadingTables())
							{
								pRapi->rpgVertColor4f(approximate_color_for_shading_entry(bottomShade).v);
							}

							calculate_wall_uvs(wallUVs, info, artTileData, pBottomMaterial, bottomCStat, bottomXPan, bottomYPan, pWall, otherV3, v3, v2, otherV2,
							                   (bottomCStat & kWallCStat_AlignOnBottom) ? get_z_coord(pSector->mCeilingZ) : get_z_coord(pOtherSector->mFloorZ));

							pRapi->rpgBegin(RPGEO_POLYGON);
							pRapi->rpgVertUV2f(wallUVs[0].v, 0);
							pRapi->rpgVertex3f(otherV3.v);
							pRapi->rpgVertUV2f(wallUVs[1].v, 0);
							pRapi->rpgVertex3f(v3.v);
							pRapi->rpgVertUV2f(wallUVs[2].v, 0);
							pRapi->rpgVertex3f(v2.v);
							pRapi->rpgVertUV2f(wallUVs[3].v, 0);
							pRapi->rpgVertex3f(otherV2.v);
							pRapi->rpgEnd();
						}

						//draw the middle masking/oneway texture
						if (pWall->mCStat & (kWallCStat_Masking | kWallCStat_OneWay))
						{
							noesisMaterial_t *pMaskMaterial = artTileData.MaterialForTile(pWall->mOverPicIndex, pWall->mPal, pWall->mShade,
							                                                              texture_flags_for_wall(), material_flags_for_wall(pWall->mCStat));

							pRapi->rpgSetMaterial((pMaskMaterial) ? pMaskMaterial->name : "defaultmaterial");

							RichVec3 maskV0 = RichVec3(v0[0], v0[1], std::min<float>(v0[2], otherV0[2]));
							RichVec3 maskV1 = RichVec3(v1[0], v1[1], std::min<float>(v1[2], otherV1[2]));
							RichVec3 maskV2 = RichVec3(v2[0], v2[1], std::max<float>(v2[2], otherV2[2]));
							RichVec3 maskV3 = RichVec3(v3[0], v3[1], std::max<float>(v3[2], otherV3[2]));

							if (!artTileData.UseShadingTables())
							{
								pRapi->rpgVertColor4f(approximate_color_for_shading_entry(pWall->mShade).v);
							}

							if (pWall->mCStat & kWallCStat_Masking)
							{
								calculate_wall_uvs(wallUVs, info, artTileData, pMaskMaterial, pWall->mCStat, pWall->mXPan, pWall->mYPan, pWall, maskV0, maskV3, maskV2, maskV1,
								                   (pWall->mCStat & kWallCStat_AlignOnBottom) ?
								                    std::max<double>(get_z_coord(pSector->mFloorZ), get_z_coord(pOtherSector->mFloorZ)) :
								                    std::min<double>(get_z_coord(pSector->mCeilingZ), get_z_coord(pOtherSector->mCeilingZ)));
							}
							else
							{
								calculate_wall_uvs(wallUVs, info, artTileData, pMaskMaterial, pWall->mCStat, pWall->mXPan, pWall->mYPan, pWall, maskV0, maskV3, maskV2, maskV1,
								                   (pWall->mCStat & kWallCStat_AlignOnBottom) ? get_z_coord(pSector->mCeilingZ) : get_z_coord(pOtherSector->mCeilingZ));
							}

							pRapi->rpgBegin(RPGEO_POLYGON);
							pRapi->rpgVertUV2f(wallUVs[0].v, 0);
							pRapi->rpgVertex3f(maskV0.v);
							pRapi->rpgVertUV2f(wallUVs[1].v, 0);
							pRapi->rpgVertex3f(maskV3.v);
							pRapi->rpgVertUV2f(wallUVs[2].v, 0);
							pRapi->rpgVertex3f(maskV2.v);
							pRapi->rpgVertUV2f(wallUVs[3].v, 0);
							pRapi->rpgVertex3f(maskV1.v);
							pRapi->rpgEnd();
						}
					}
				}
			}
		}
		pRapi->rpgSetName(NULL);
	}

	uint16_t material_flags_for_sprite(const int16_t cStat)
	{
		uint16_t materialFlags = CArtTileData::skMaterialFlags_None;
		if (!(cStat & kSprCStat_OneSided))
		{
			materialFlags |= CArtTileData::skMaterialFlags_TwoSided;
		}
		if (cStat & kSprCStat_Translucence)
		{
			materialFlags |= CArtTileData::skMaterialFlags_Translucence;
		}
		const uint32_t facingType = ((cStat & kSprCStat_FaceMask) >> kSprCStat_FaceOffset);
		if (facingType == kSpriteFace_Facing)
		{
			materialFlags |= CArtTileData::skMaterialFlags_FacingSprite;
		}
		return materialFlags;
	}

	void draw_sprites(CArtTileData &artTileData, const SMapInfo &info, noeRAPI_t *pRapi)
	{
		char spriteMeshName[MAX_NOESIS_PATH];
		for (uint32_t spriteIndex = 0; spriteIndex < info.mSpriteCount; ++spriteIndex)
		{
			const SMapSprite *pSprite = info.mpSprites + spriteIndex;
			if (abs(pSprite->mPos[0]) > skMaxBuildMapDimension || abs(pSprite->mPos[0]) > skMaxBuildMapDimension)
			{
				continue;
			}

			if (g_buildMapOpts->mSpriteMode != kSpriteMode_All)
			{
				if ((pSprite->mPicIndex >= skSpriteSpecialPicIndexBegin && pSprite->mPicIndex <= skSpriteSpecialPicIndexEnd) || pSprite->mPicIndex == skShadowWarriorStSprite)
				{
					continue;
				}
			}

			noesisMaterial_t *pSpriteMaterial = artTileData.MaterialForTile(pSprite->mPicIndex, pSprite->mPal, pSprite->mShade,
			                                                                CArtTileFile::skTextureFlags_None, material_flags_for_sprite(pSprite->mCStat));
			noesisTex_t *pSpriteTexture = artTileData.TextureForMaterial(pSpriteMaterial);
			if (pSpriteTexture)
			{
				const RichVecH2 pos = get_xy_coord(pSprite->mPos);
				const double posZ = get_z_coord(pSprite->mPos[2]);

				const uint32_t facingType = ((pSprite->mCStat & kSprCStat_FaceMask) >> kSprCStat_FaceOffset);
				const float spriteAngle = (float)pSprite->mAngle / 2047.0f * g_flPI * 2.0f;

				const float xRepeat = (float)pSprite->mXRepeat / 64.0f;
				const float yRepeat = (float)pSprite->mYRepeat / 64.0f;
				const RichVec2 tileToWorld(xRepeat * 16.0f, yRepeat * 16.0f);
				const RichVec2 spriteSize = RichVec2((float)pSpriteTexture->w, (float)pSpriteTexture->h) * tileToWorld;

				int8_t xOffset, yOffset;
				artTileData.GetTileXYOffsets(&xOffset, &yOffset, pSprite->mPicIndex);

				RichVec3 drawRight(1.0f, 0.0f, 0.0f);
				RichVec3 drawUp(0.0f, 0.0f, 1.0f);
				RichVec3 drawPos((float)pos[0], (float)pos[1], (float)posZ);
				float uvX = 1.0f;
				float uvY = 1.0f;
				switch (facingType)
				{
				case kSpriteFace_Facing:
				case kSpriteFace_Wall:
					drawRight[0] = sinf(spriteAngle);
					drawRight[1] = cosf(spriteAngle);
					drawRight[2] = 0.0f;
					if (!(pSprite->mCStat & kSprCStat_Centered))
					{
						drawPos[2] += spriteSize[1] * 0.5f;
					}

					if (facingType == kSpriteFace_Wall)
					{ //Build doesn't actually use the x offset for anything in the facing case
						drawPos[0] += drawRight[0] * (float)xOffset * tileToWorld[0];
						drawPos[1] += drawRight[1] * (float)xOffset * tileToWorld[0];
					}
					drawPos[2] += yOffset * tileToWorld[1];

					uvX *= (pSprite->mCStat & kSprCStat_XFlip) ? -1.0f : 1.0f;
					uvY *= (pSprite->mCStat & kSprCStat_YFlip) ? -1.0f : 1.0f;

					//if we're aligned to a wall, see how close we are to it and fudge our way out a bit as needed
					if (!g_buildMapOpts->mNoSpriteFudge &&
					    pSprite->mSectorIndex >= 0 && (uint32_t)pSprite->mSectorIndex < info.mSectorCount && facingType == kSpriteFace_Wall)
					{
						const SMapSector *pSector = info.mpSectors + pSprite->mSectorIndex;
						for (int32_t wallIndex = 0; wallIndex < pSector->mWallCount; ++wallIndex)
						{
							const int32_t absWallIndex = pSector->mWallIndex + wallIndex;
							const SMapWall *pWall = info.mpWalls + absWallIndex;
							const SMapWall *pNextWall = info.mpWalls + pWall->mNextWall;
							const RichVecH2 wallPos = get_xy_coord(pWall->mPos);
							const RichVecH2 nextWallPos = get_xy_coord(pNextWall->mPos);
							const RichVecH2 spriteOnSegment = pos.PointOnSegment(wallPos, nextWallPos);
							if ((pos - spriteOnSegment).LengthSq() <= skSpriteCloseEnoughToWallSquared)
							{
								//it's close enough to this particular segment, push it away from the wall
								const RichVecH2 toNextWall = (nextWallPos - wallPos).Normalized();
								drawPos[0] += (float)toNextWall[1] * skSpriteFudgeDistance;
								drawPos[1] -= (float)toNextWall[0] * skSpriteFudgeDistance;
								break;
							}
						}
					}
					break;
				case kSpriteFace_Floor:
					drawRight[0] = sinf(spriteAngle);
					drawRight[1] = cosf(spriteAngle);
					drawRight[2] = 0.0f;
					drawUp[0] = drawRight[1];
					drawUp[1] = -drawRight[0];
					drawUp[2] = 0.0f;
					
					drawPos -= drawRight * ((float)xOffset * tileToWorld[0]);
					drawPos -= drawUp * ((float)yOffset * tileToWorld[1]);

					uvX = -uvX;
					uvY = -uvY;

					drawRight *= (pSprite->mCStat & kSprCStat_XFlip) ? -1.0f : 1.0f;
					drawUp *= (pSprite->mCStat & kSprCStat_YFlip) ? -1.0f : 1.0f;

					//see if we need to bump a bit out of the floor or ceiling
					if (!g_buildMapOpts->mNoSpriteFudge &&
					    pSprite->mSectorIndex >= 0 && (uint32_t)pSprite->mSectorIndex < info.mSectorCount)
					{
						const SMapSector *pSector = info.mpSectors + pSprite->mSectorIndex;
						const double floorZ = get_z_coord(pSector->mFloorZ);
						const double ceilingZ = get_z_coord(pSector->mCeilingZ);
						if (fabs(posZ - floorZ) < skSpriteCloseEnoughToFloor)
						{
							drawPos[2] += skSpriteFudgeDistance;
						}
						else if (fabs(ceilingZ - posZ) < skSpriteCloseEnoughToFloor)
						{
							drawPos[2] -= skSpriteFudgeDistance;
						}
					}
					break;
				}

				drawRight *= spriteSize[0] * 0.5f;
				drawUp *= spriteSize[1] * 0.5f;

				RichVec3 v0 = drawPos - drawRight - drawUp;
				RichVec3 v1 = drawPos - drawRight + drawUp;
				RichVec3 v2 = drawPos + drawRight + drawUp;
				RichVec3 v3 = drawPos + drawRight - drawUp;

				sprintf_s(spriteMeshName, "sprite%04i", spriteIndex);
				pRapi->rpgSetName(spriteMeshName);

				pRapi->rpgSetMaterial(pSpriteMaterial->name);

				if (!artTileData.UseShadingTables())
				{
					pRapi->rpgVertColor4f(approximate_color_for_shading_entry(pSprite->mShade).v);
				}

				pRapi->rpgBegin(RPGEO_POLYGON);
				pRapi->rpgVertUV2f(RichVec2(uvX, uvY).v, 0);
				pRapi->rpgVertex3f(v0.v);
				pRapi->rpgVertUV2f(RichVec2(uvX, 0.0f).v, 0);
				pRapi->rpgVertex3f(v1.v);
				pRapi->rpgVertUV2f(RichVec2(0.0f, 0.0f).v, 0);
				pRapi->rpgVertex3f(v2.v);
				pRapi->rpgVertUV2f(RichVec2(0.0f, uvY).v, 0);
				pRapi->rpgVertex3f(v3.v);
				pRapi->rpgEnd();
			}
		}
		pRapi->rpgSetName(NULL);
	}
}

bool Model_Build_CheckMap(BYTE *fileBuffer, int bufferLen, noeRAPI_t *rapi)
{
	SMapInfo info;
	if (!get_map_info(&info, fileBuffer, bufferLen))
	{
		return false;
	}

	return true;
}

noesisModel_t *Model_Build_LoadMap(BYTE *fileBuffer, int bufferLen, int &numMdl, noeRAPI_t *rapi)
{
	SMapInfo info;
	if (!get_map_info(&info, fileBuffer, bufferLen))
	{
		return NULL;
	}

	void *pCtx = rapi->rpgCreateContext();

	CArtTileData artTileData(rapi);

	TPerSectorDataList perSectorData;

	generate_sector_data(perSectorData, info, rapi);

	//this would be a good place to perform optional overlapping sector relocation.
	//the idea is to walk the sectors, then see which ones overlap after hole-cutting. when a sector overlaps, walk its walls into other sectors to build
	//up a list of connected overlapping sectors. once overlapping sectors have been flooded without self-overlapping, create a transform (can be set upon
	//draw with rpgSetTransform) which moves the group of sectors over to unoccupied space to be applied at draw time, and create portal edges for every
	//wall that connects between the relocated and non-relocated sectors.
	//at draw time, use the portal edges to create portal materials for each sector portal connection and draw them. this will allow exported maps to be
	//easily adapted to games/engines which support portals.

	draw_map_geometry(artTileData, perSectorData, info, rapi);

	if (g_buildMapOpts->mSpriteMode != kSpriteMode_None)
	{
		draw_sprites(artTileData, info, rapi);
	}

	rapi->rpgOptimize();

	noesisMatData_t *pMd = artTileData.CreateNoesisMaterialData();
	if (pMd)
	{
		rapi->rpgSetExData_Materials(pMd);
	}

	noesisModel_t *pMdl = rapi->rpgConstructModel();
	rapi->rpgDestroyContext(pCtx);

	if (pMdl)
	{
		static float mdlAngOfs[3] = { 0.0f, 270.0f, 0.0f };
		rapi->SetPreviewAngOfs(mdlAngOfs);
		numMdl = 1;
	}
	return pMdl;
}

#define BUILDMAP_DECL_OPTS(argRequired) \
	buildMapOpts_t *lopts = (buildMapOpts_t *)store; \
	assert(storeSize == sizeof(buildMapOpts_t)); \
	if (argRequired && !arg) \
	{ \
		return false; \
	}

bool Model_Build_MapShTableHandler(const char *arg, unsigned char *store, int storeSize)
{
	BUILDMAP_DECL_OPTS(false);
	lopts->mUseShadingTables = true;
	return true;
}

bool Model_Build_MapTNoAlignHandler(const char *arg, unsigned char *store, int storeSize)
{
	BUILDMAP_DECL_OPTS(false);
	lopts->mNoAlignTileHeight = true;
	return true;
}

bool Model_Build_MapNoFudgeHandler(const char *arg, unsigned char *store, int storeSize)
{
	BUILDMAP_DECL_OPTS(false);
	lopts->mNoSpriteFudge = true;
	return true;
}

bool Model_Build_MapNameSecsHandler(const char *arg, unsigned char *store, int storeSize)
{
	BUILDMAP_DECL_OPTS(false);
	lopts->mNameSectors = true;
	return true;
}

bool Model_Build_MapSkipParaHandler(const char *arg, unsigned char *store, int storeSize)
{
	BUILDMAP_DECL_OPTS(false);
	lopts->mSkipParallax = true;
	return true;
}

bool Model_Build_MapSpriteModeHandler(const char *arg, unsigned char *store, int storeSize)
{
	BUILDMAP_DECL_OPTS(true);
	lopts->mSpriteMode = atoi(arg);
	return true;
}