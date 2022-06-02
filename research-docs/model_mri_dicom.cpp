#include "stdafx.h"
#include "CharLS/interface.h"
#include <float.h>
#include <algorithm>

dicomOpts_t *g_dicomOpts = NULL;

enum EDicomTransferSyntax
{
	kDTS_Unknown = 0,

	kDTS_ImplicitVRLittleEndian,
	kDTS_ExplicitVRLittleEndian,
	kDTS_ExplicitVRBigEndian,

	kDTS_RLE,	kDTS_JpegBaseline,
	kDTS_JpegExtended,
	kDTS_JpegSpectral,
	kDTS_JpegProgressive,
	kDTS_JpegLossless,
	kDTS_JpegLosslessFirstOrder,
	kDTS_JpegLSLossless,
	kDTS_JpegLSNearLossless,
	kDTS_Jpeg2000LosslessReversible,
	kDTS_Jpeg2000LosslessOrLossy,
	kDTS_Jpeg2000Part2LosslessReversible,
	kDTS_Jpeg2000Part2LosslessOrLossy,
	kDTS_MPEG2_ML,
	kDTS_MPEG2_HL,
	kDTS_MPEG4,
	kDTS_MPEG4Temporal,

	kDTS_Deflate,

	kDTS_Count
};

static const char *skTransferSyntaxStrings[kDTS_Count] =
{
	"Unknown",
	"1.2.840.10008.1.2",	"1.2.840.10008.1.2.1",	"1.2.840.10008.1.2.2",
	"1.2.840.10008.1.2.5",
	"1.2.840.10008.1.2.4.50",	"1.2.840.10008.1.2.4.51",	"1.2.840.10008.1.2.4.53",	"1.2.840.10008.1.2.4.55",	"1.2.840.10008.1.2.4.57",	"1.2.840.10008.1.2.4.70",	"1.2.840.10008.1.2.4.80",	"1.2.840.10008.1.2.4.81",	"1.2.840.10008.1.2.4.90",	"1.2.840.10008.1.2.4.91",	"1.2.840.10008.1.2.4.92",	"1.2.840.10008.1.2.4.93",
	"1.2.840.10008.1.2.4.100",	"1.2.840.10008.1.2.4.101",	"1.2.840.10008.1.2.4.102",	"1.2.840.10008.1.2.4.103",
	"1.2.840.10008.1.2.1.99"};

const EDicomTransferSyntax find_transfer_syntax_for_string(const char *pSyntaxString)
{
	for (int tsIndex = 0; tsIndex < kDTS_Count; ++tsIndex)
	{
		if (!strcmp(skTransferSyntaxStrings[tsIndex], pSyntaxString))
		{
			return EDicomTransferSyntax(tsIndex);
		}
	}

	return kDTS_Unknown;
}

const bool is_jpeg_transfer_syntax(const EDicomTransferSyntax transferSyntax)
{
	return (transferSyntax >= kDTS_JpegBaseline && transferSyntax <= kDTS_Jpeg2000Part2LosslessOrLossy);
}enum EDicomPhotometricInterpretation
{
	kDPI_Unknown = 0,

	kDPI_Monochrome1,
	kDPI_Monochrome2,
	kDPI_PaletteColor,
	kDPI_RGB,
	kDPI_HSV,	kDPI_ARGB,	kDPI_CMYK,	kDPI_YBR_Full,
	kDPI_YBR_Full_422,
	kDPI_YBR_Partial_422,
	kDPI_YBR_Partial_420,
	kDPI_YBR_ICT,
	kDPI_YBR_RCT,

	kDPI_Count
};

static const char *skPhotometricInterpretationStrings[kDPI_Count] =
{
	"Unknown",
	"MONOCHROME1",	"MONOCHROME2",	"PALETTE COLOR",	"RGB",	"HSV",	"ARGB",	"CMYK",	"YBR_FULL",	"YBR_FULL_422",	"YBR_PARTIAL_422",	"YBR_PARTIAL_420",	"YBR_ICT",	"YBR_RCT"};

const EDicomPhotometricInterpretation photometric_interpretation_for_string(const char *pPhotoString)
{
	for (int piIndex = 0; piIndex < kDPI_Count; ++piIndex)
	{
		if (!stricmp(skPhotometricInterpretationStrings[piIndex], pPhotoString))
		{
			return EDicomPhotometricInterpretation(piIndex);
		}
	}

	return kDPI_Unknown;
}static const unsigned short skVR_ApplicationEntity = 'EA';static const unsigned short skVR_AgeString = 'SA';static const unsigned short skVR_AttributeTag = 'TA';static const unsigned short skVR_CodeString = 'SC';static const unsigned short skVR_Date = 'AD';static const unsigned short skVR_DecimalString = 'SD';static const unsigned short skVR_DateTime = 'TD';static const unsigned short skVR_Float = 'LF';static const unsigned short skVR_Double = 'DF';static const unsigned short skVR_IntString = 'SI';static const unsigned short skVR_LongString = 'OL';static const unsigned short skVR_LongText = 'TL';static const unsigned short skVR_OtherByte = 'BO';static const unsigned short skVR_OtherFloat = 'FO';static const unsigned short skVR_OtherWord = 'WO';static const unsigned short skVR_PersonName = 'NP';static const unsigned short skVR_ShortString = 'HS';static const unsigned short skVR_SignedLong = 'LS';static const unsigned short skVR_Sequence = 'QS';static const unsigned short skVR_SignedShort = 'SS';static const unsigned short skVR_ShortText = 'TS';static const unsigned short skVR_Time = 'MT';static const unsigned short skVR_UID = 'IU';static const unsigned short skVR_UnsignedLong = 'LU';static const unsigned short skVR_Unknown = 'NU';static const unsigned short skVR_UnsignedShort = 'SU';static const unsigned short skVR_UnlimitedText = 'TU';static const unsigned short skVR_Invalid = 0;static const unsigned short skExplicitVRsFor32BitLength[] =
{
	skVR_OtherByte,
	skVR_OtherWord,
	skVR_OtherFloat,
	skVR_Sequence,
	skVR_UnlimitedText,
	skVR_Unknown
};
static const int skExplicitVRsFor32BitLengthCount = sizeof(skExplicitVRsFor32BitLength) / sizeof(unsigned short);

static const int skHeaderOffset = 128;
static const int skDataElemsOffset = skHeaderOffset + 4;

static const unsigned int skTemporaryStringElementValueSize = 512;

static const unsigned short skGroup2 = 0x0002;
static const unsigned short skG2TransferSyntaxUID = 0x0010;

static const unsigned short skGroupDelimter = 0xFFFE;

#define MAKE_ELEMENT_ID(groupNum, elemNum) (groupNum | (elemNum << 16))

static const unsigned int skFrameTimeElement = MAKE_ELEMENT_ID(0x0018, 0x1063);
static const unsigned int skWaveformDataElement = MAKE_ELEMENT_ID(0x5400, 0x1010);
static const unsigned int skRedPaletteLookupTableDataElement = MAKE_ELEMENT_ID(0x0028, 0x1201);
static const unsigned int skGreenPaletteLookupTableDataElement = MAKE_ELEMENT_ID(0x0028, 0x1202);
static const unsigned int skBluePaletteLookupTableDataElement = MAKE_ELEMENT_ID(0x0028, 0x1203);
static const unsigned int skAlphaPaletteLookupTableDataElement = MAKE_ELEMENT_ID(0x0028, 0x1204);
static const unsigned int skRedPaletteLookupTableDescElement = MAKE_ELEMENT_ID(0x0028, 0x1101);
static const unsigned int skGreenPaletteLookupTableDescElement = MAKE_ELEMENT_ID(0x0028, 0x1102);
static const unsigned int skBluePaletteLookupTableDescElement = MAKE_ELEMENT_ID(0x0028, 0x1103);
static const unsigned int skAlphaPaletteLookupTableDescElement = MAKE_ELEMENT_ID(0x0028, 0x1104);
static const unsigned int skRedSegPaletteLookupTableDataElement = MAKE_ELEMENT_ID(0x0028, 0x1221);
static const unsigned int skGreenSegPaletteLookupTableDataElement = MAKE_ELEMENT_ID(0x0028, 0x1222);
static const unsigned int skBlueSegPaletteLookupTableDataElement = MAKE_ELEMENT_ID(0x0028, 0x1223);
static const unsigned int skLookupTableDataElement = MAKE_ELEMENT_ID(0x0028, 0x3006);
static const unsigned int skLookupTableDescElement = MAKE_ELEMENT_ID(0x0028, 0x3002);
static const unsigned int skBlendingLookupTableDataElement = MAKE_ELEMENT_ID(0x0028, 0x1408);
static const unsigned int skOverlayDataBaseElement = MAKE_ELEMENT_ID(0x6000, 0x3000);static const unsigned int skPixelDataSamplesPerPixelElement = MAKE_ELEMENT_ID(0x0028, 0x0002);
static const unsigned int skPixelDataPhotometricInterpretationElement = MAKE_ELEMENT_ID(0x0028, 0x0004);
static const unsigned int skPixelDataRowsElement = MAKE_ELEMENT_ID(0x0028, 0x0010);
static const unsigned int skPixelDataColumnsElement = MAKE_ELEMENT_ID(0x0028, 0x0011);
static const unsigned int skPixelDataBitsAllocatedElement = MAKE_ELEMENT_ID(0x0028, 0x0100);
static const unsigned int skPixelDataBitsStoredElement = MAKE_ELEMENT_ID(0x0028, 0x0101);
static const unsigned int skPixelDataHighBitElement = MAKE_ELEMENT_ID(0x0028, 0x0102);
static const unsigned int skPixelDataRepresentationElement = MAKE_ELEMENT_ID(0x0028, 0x0103);
static const unsigned int skPixelDataElement = MAKE_ELEMENT_ID(0x7FE0, 0x0010);
static const unsigned int skPixelDataPlanarConfigurationElement = MAKE_ELEMENT_ID(0x0028, 0x0006);
static const unsigned int skPixelDataFrameCountElement = MAKE_ELEMENT_ID(0x0028, 0x0008);
static const unsigned int skPixelDataFrameIncrementPointerElement = MAKE_ELEMENT_ID(0x0028, 0x0009);
static const unsigned int skPixelDataAspectRatioElement = MAKE_ELEMENT_ID(0x0028, 0x0034);
static const unsigned int skPixelDataSmallestValueElement = MAKE_ELEMENT_ID(0x0028, 0x0106);
static const unsigned int skPixelDataLargestValueElement = MAKE_ELEMENT_ID(0x0028, 0x0107);
static const unsigned int skPixelDataICCProfileElement = MAKE_ELEMENT_ID(0x0028, 0x2000);
static const unsigned int skPixelDataRescaleIntercept = MAKE_ELEMENT_ID(0x0028, 0x1052);
static const unsigned int skPixelDataRescaleSlope = MAKE_ELEMENT_ID(0x0028, 0x1053);static const unsigned int skFloatPixelDataElement = MAKE_ELEMENT_ID(0x7FE0, 0x0008);
static const unsigned int skDoublePixelDataElement = MAKE_ELEMENT_ID(0x7FE0, 0x0009);
static const unsigned int skSequenceTag = MAKE_ELEMENT_ID(0xFFFE, 0xE000);
static const unsigned int skSequenceEndTag = MAKE_ELEMENT_ID(0xFFFE, 0xE0DD);const char *temporary_string_for_element_value(RichBitStreamEx &bs, const unsigned int valueLength)
{
	static char sReadBuffer[skTemporaryStringElementValueSize];
	const int readLength = std::min<unsigned int>(valueLength, skTemporaryStringElementValueSize-1);
	bs.ReadBytes(sReadBuffer, readLength);
	sReadBuffer[readLength] = 0;	for (int trailingWhiteSpace = readLength - 1; trailingWhiteSpace > 0; --trailingWhiteSpace)
	{
		if (sReadBuffer[trailingWhiteSpace] == ' ' ||
			sReadBuffer[trailingWhiteSpace] == '\r' ||
			sReadBuffer[trailingWhiteSpace] == '\n' ||
			sReadBuffer[trailingWhiteSpace] == 9)
		{
			sReadBuffer[trailingWhiteSpace] = 0;
		}
		else if (sReadBuffer[trailingWhiteSpace] != 0)
		{
			break;
		}
	}

	return sReadBuffer;
}

template<class DestType>
static const DestType read_single_element_value_for_vr(RichBitStreamEx &bs,
														const unsigned short vr, const unsigned int valueLength)
{
	switch (vr)
	{
	case skVR_Double:
		return (DestType)bs.ReadDouble();
	case skVR_Float:
	case skVR_OtherFloat:
		return (DestType)bs.ReadFloat();
	case skVR_SignedLong:
		return (DestType)bs.ReadInt();
	case skVR_UnsignedLong:
		return (DestType)bs.ReadUInt();
	case skVR_SignedShort:
		return (DestType)bs.ReadShort();
	case skVR_UnsignedShort:
	case skVR_OtherWord:
	case skVR_AttributeTag:
		return (DestType)bs.ReadUShort();
	case skVR_OtherByte:
		return (DestType)bs.ReadByte();
	case skVR_IntString:
	case skVR_LongString:
	case skVR_ShortString:
		{
			const char *pTempBuffer = temporary_string_for_element_value(bs, valueLength);
			return (DestType)atoi(pTempBuffer);
		}
	case skVR_DecimalString:
		{
			const char *pTempBuffer = temporary_string_for_element_value(bs, valueLength);
			return (DestType)atof(pTempBuffer);
		}
	case skVR_Invalid:
		{			switch (valueLength)
			{
			case 1:
				return (DestType)bs.ReadByte();
			case 2:
				return (DestType)bs.ReadUShort();
			case 4:
				return (DestType)bs.ReadUInt();
			default:
				return 0;
			}
		}
	default:
		return 0;
	}
}struct SDicomPalette
{
	SDicomPalette()
		: mEntryCount(0)
		, mFirstMappedEntry(0)
		, mBitsPerEntry(0)
		, mpData(NULL)
		, mDataLength(0)
		, mDataVR(skVR_Invalid)
	{
	}

	union
	{
		unsigned int mDescriptor[3];
		struct
		{
			unsigned int mEntryCount;
			unsigned int mFirstMappedEntry;
			unsigned int mBitsPerEntry;
		};
	};

	unsigned char *mpData;
	int mDataLength;
	unsigned short mDataVR;
};

struct SDicomImage
{
	SDicomImage()
		: mpData(NULL)
		, mDataLength(0)
		, mDataVR(skVR_Invalid)
		, mSamplesPerPixel(0)
		, mBitsPerChannel(0)
		, mBitsStoredPerChannel(0)
		, mHighBit(0)
		, mPhotometricInterpretation(kDPI_Unknown)
		, mPlanarConfiguration(0)
		, mRowCount(0)
		, mColumnCount(0)
		, mSliceCount(0)
		, mRescaleIntercept(0.0f)
		, mRescaleSlope(1.0f)
	{
	}

	unsigned char *mpData;
	int mDataLength;	unsigned short mDataVR;

	int mSamplesPerPixel;
	int mBitsPerChannel;
	int mBitsStoredPerChannel;
	int mHighBit;
	EDicomPhotometricInterpretation mPhotometricInterpretation;
	int mPlanarConfiguration;
	int mRowCount;
	int mColumnCount;
	int mSliceCount;	float mRescaleIntercept;
	float mRescaleSlope;

	SDicomPalette mPaletteRgba[4];
};

class CDicomDataElement
{
public:	explicit CDicomDataElement(RichBitStreamEx &bs, const EDicomTransferSyntax transferSyntax)
	{
		bs.SetFlags(bs.GetFlags() & ~BITSTREAMFL_BIGENDIAN);
		mGroupNum = bs.ReadUShort();		if (SetStreamEndian(bs, transferSyntax) && mGroupNum != skGroup2)
		{			LITTLE_BIG_SWAP(mGroupNum);
		}

		mElemNum = bs.ReadUShort();

		bool isStandardElem = true;
		const bool isImplicitVR = (transferSyntax == kDTS_ImplicitVRLittleEndian && mGroupNum != skGroup2);
		if (isImplicitVR)
		{			if ((mElementId & 0xFFFFFF00) == skOverlayDataBaseElement)
			{				mVR = skVR_OtherWord;
			}
			else
			{
				switch (mElementId)
				{
				case skPixelDataElement:
				case skWaveformDataElement:
				case skRedPaletteLookupTableDataElement:
				case skGreenPaletteLookupTableDataElement:
				case skBluePaletteLookupTableDataElement:
				case skAlphaPaletteLookupTableDataElement:
				case skRedSegPaletteLookupTableDataElement:
				case skGreenSegPaletteLookupTableDataElement:
				case skBlueSegPaletteLookupTableDataElement:
				case skLookupTableDataElement:
				case skBlendingLookupTableDataElement:
					mVR = skVR_OtherWord;
					break;
				case skRedPaletteLookupTableDescElement:
				case skGreenPaletteLookupTableDescElement:
				case skBluePaletteLookupTableDescElement:
				case skAlphaPaletteLookupTableDescElement:
				case skLookupTableDescElement:
					mVR = skVR_UnsignedShort;
					break;
				case skPixelDataRescaleIntercept:
				case skPixelDataRescaleSlope:
					mVR = skVR_DecimalString;
					break;
				default:
					mVR = skVR_Invalid;
					break;
				}
			}
		}
		else if (mGroupNum == skGroupDelimter)
		{
			mVR = skVR_Invalid;
		}
		else
		{			mVR = bs.ReadByte() | ((unsigned short)bs.ReadByte() << 8);
			isStandardElem = !ExplicitVRFor32BitLength();
		}

		if (isStandardElem)
		{			mValueLength = (isImplicitVR || mGroupNum == skGroupDelimter) ? bs.ReadUInt() : bs.ReadUShort();
		}
		else
		{
			bs.ReadUShort();			mValueLength = bs.ReadUInt();
		}

		mValueOfs = bs.GetOffset();

		if (mGroupNum == skGroupDelimter || mVR == skVR_Sequence)
		{			mValueLength = 0;
		}
		else if (mValueLength == 0xFFFFFFFF)
		{			unsigned int delimiter = bs.ReadUInt();
			if (delimiter != skSequenceTag)
			{				mValueLength = 0;
			}
			else
			{
				while (delimiter == skSequenceTag || delimiter == skSequenceEndTag)
				{
					const int seqSegSize = bs.ReadInt();
					if (seqSegSize < 0)
					{
						break;
					}

					bs.SetOffset(bs.GetOffset() + seqSegSize);
					if (delimiter == skSequenceEndTag)
					{						break;
					}
					delimiter = bs.ReadUInt();
				}
				mValueLength = bs.GetOffset() - mValueOfs;
			}			bs.SetOffset(mValueOfs);
		}
	}

	explicit CDicomDataElement(const unsigned int elementId, const unsigned short vr)
		: mElementId(elementId)
		, mVR(vr)
		, mValueLength(0)
		, mValueOfs(0)
	{
	}

	explicit CDicomDataElement(const unsigned short groupNum, const unsigned short elemNum,
								const unsigned short vr)
		: mGroupNum(groupNum)
		, mElemNum(elemNum)
		, mVR(vr)
		, mValueLength(0)
		, mValueOfs(0)
	{
	}

	void PrepDataStreamForValueRead(RichBitStreamEx &bs, const EDicomTransferSyntax transferSyntax) const
	{		SetStreamEndian(bs, transferSyntax);
		bs.SetOffset(mValueOfs);
	}

	void SetStreamToNextDataElement(RichBitStreamEx &bs) const
	{
		bs.SetOffset(mValueOfs + mValueLength);
	}

	template<class DestType>
	const DestType ReadSingleElementValue(RichBitStreamEx &bs, const EDicomTransferSyntax transferSyntax) const
	{
		PrepDataStreamForValueRead(bs, transferSyntax);
		return read_single_element_value_for_vr<DestType>(bs, mVR, mValueLength);
	}

	template<class DestType>
	void ReadArrayElementValues(DestType *pOutValues, const int valueCount, RichBitStreamEx &bs,
								const EDicomTransferSyntax transferSyntax) const
	{
		PrepDataStreamForValueRead(bs, transferSyntax);
		for (int valueIndex = 0; valueIndex < valueCount; ++valueIndex)
		{
			pOutValues[valueIndex] = read_single_element_value_for_vr<DestType>(bs, mVR, mValueLength);
		}
	}	const char *TemporaryStringForElementValue(RichBitStreamEx &bs) const
	{
		return temporary_string_for_element_value(bs, mValueLength);
	}

	const unsigned short GetGroupNum() const { return mGroupNum; }
	const unsigned short GetElemNum() const { return mElemNum; }
	const unsigned int GetElementId() const { return mElementId; }
	const unsigned short GetVR() const { return mVR; }
	const unsigned int GetValueLength() const { return mValueLength; }
	const unsigned int GetValueOfs() const { return mValueOfs; }

	void WriteToStream(RichBitStreamEx &bs, const EDicomTransferSyntax transferSyntax,
						const void *pData, const int dataSize) const
	{		bs.WriteUShort(mGroupNum);
		bs.WriteUShort(mElemNum);
		const unsigned char *pVR = (const unsigned char *)&mVR;
		bs.WriteByte(pVR[0]);
		bs.WriteByte(pVR[1]);

		const int alignedSize = ((dataSize + 1) & ~1);
		if (!ExplicitVRFor32BitLength())
		{
			bs.WriteUShort((unsigned short)alignedSize);
		}
		else
		{
			bs.WriteUShort(0);			bs.WriteUInt(alignedSize);
		}

		if (pData)
		{			bs.WriteBytes(pData, dataSize);
			if (alignedSize > dataSize)
			{				bs.WriteByte(0);
			}
		}
	}

	template<class DataType>
	void WriteTypeToStream(RichBitStreamEx &bs, const EDicomTransferSyntax transferSyntax,
							const DataType &data) const
	{
		WriteToStream(bs, transferSyntax, &data, sizeof(DataType));
	}

	void WriteStringToStream(RichBitStreamEx &bs, const EDicomTransferSyntax transferSyntax,
								const char *pDataString) const
	{		const int stringLength = (int)strlen(pDataString);
		WriteToStream(bs, transferSyntax, pDataString, stringLength);
	}

private:
	bool SetStreamEndian(RichBitStreamEx &bs, const EDicomTransferSyntax transferSyntax) const
	{
		bool isBigEndian = (transferSyntax == kDTS_ExplicitVRBigEndian);
		const int flags = bs.GetFlags();
		const int streamEndianFlags = (mGroupNum == skGroup2 || !isBigEndian) ?
										(flags & ~BITSTREAMFL_BIGENDIAN) :
										(flags | BITSTREAMFL_BIGENDIAN);
		bs.SetFlags(streamEndianFlags);
		return isBigEndian;
	}

	bool ExplicitVRFor32BitLength() const
	{
		for (int vrCheckIndex = 0; vrCheckIndex < skExplicitVRsFor32BitLengthCount; ++vrCheckIndex)
		{
			if (skExplicitVRsFor32BitLength[vrCheckIndex] == mVR)
			{				return true;
			}
		}
		return false;
	}	union
	{
		unsigned int mElementId;
		struct
		{
			unsigned short mGroupNum;
			unsigned short mElemNum;
		};
	};

	unsigned short mVR;

	unsigned int mValueLength;

	unsigned int mValueOfs;};

static const EDicomTransferSyntax find_transfer_syntax(RichBitStreamEx &bs)
{
	while (bs.GetOffset() < bs.GetSize())
	{		const CDicomDataElement elem(bs, kDTS_Unknown);
		if (elem.GetGroupNum() != skGroup2)
		{			return kDTS_Unknown;
		}
		const int endOfElemData = int(elem.GetValueOfs() + elem.GetValueLength());
		if (endOfElemData <= 0 || endOfElemData >= bs.GetSize())
		{			return kDTS_Unknown;
		}

		if (elem.GetElemNum() == skG2TransferSyntaxUID)
		{			bs.SetOffset(elem.GetValueOfs());
			const char *pTransferSyntaxString = elem.TemporaryStringForElementValue(bs);			elem.SetStreamToNextDataElement(bs);

			return find_transfer_syntax_for_string(pTransferSyntaxString);
		}
		else
		{			elem.SetStreamToNextDataElement(bs);
		}
	}

	return kDTS_Unknown;
}

bool Image_MRI_CheckDicom(BYTE *fileBuffer, int bufferLen, noeRAPI_t *rapi)
{
	if (bufferLen <= skDataElemsOffset)
	{
		return false;
	}
	if (memcmp(fileBuffer + skHeaderOffset, "DICM", 4) != 0)
	{
		return false;
	}

	RichBitStreamEx bs(fileBuffer, bufferLen);
	bs.SetOffset(skDataElemsOffset);

	const EDicomTransferSyntax transferSyntax = find_transfer_syntax(bs);
	return transferSyntax != kDTS_Unknown;
}

static void converted_float_to_rgb(unsigned char *pRgbOut, const int channelsOut,
									const int width, const int height, const float *pConvertedFloat,
									const int channelsPerPixel, const unsigned short sourceVR,
									const float minSampleVal, const float maxSampleVal)
{
	const float sampleRange = (maxSampleVal - minSampleVal);
	for (int pixelIndex = 0; pixelIndex < width * height; ++pixelIndex)
	{
		unsigned char *pRgbDst = pRgbOut + pixelIndex * channelsOut;
		const float *pFloatSrc = pConvertedFloat + pixelIndex * channelsPerPixel;
		for (int channelIndex = 0; channelIndex < channelsPerPixel; ++channelIndex)
		{
			if (sourceVR == skVR_OtherByte)
			{				pRgbDst[channelIndex] = (unsigned char)pFloatSrc[channelIndex];
			}
			else
			{				const float v = (pFloatSrc[channelIndex] - minSampleVal) / sampleRange;
				pRgbDst[channelIndex] = (unsigned char)(v * 255.0f);
			}
		}		for (int remainingChannelIndex = channelsPerPixel; remainingChannelIndex < channelsOut; ++remainingChannelIndex)
		{
			pRgbDst[remainingChannelIndex] = (remainingChannelIndex == 3) ? 255 : pRgbDst[0];
		}
	}
}

static float normalize_value_for_image_data(const float value, const SDicomImage &dicomImage)
{
	float valueOut = value;
	if (dicomImage.mDataVR == skVR_OtherWord &&
		dicomImage.mBitsPerChannel > 0)
	{
		valueOut /= (float)((1 << dicomImage.mBitsPerChannel) - 1);
	}
	else
	{
		float scale;
		switch (dicomImage.mDataVR)
		{
		case skVR_SignedLong:
			scale = 1.0f / 2147483647.0f;
			break;
		case skVR_UnsignedLong:
			scale = 1.0f / 4294967295.0f;
			break;
		case skVR_SignedShort:
			scale = 1.0f / 32767.0f;
			break;
		case skVR_UnsignedShort:
		case skVR_OtherWord:
			scale = 1.0f / 65535.0f;
			break;
		case skVR_OtherByte:
			scale = 1.0f / 255.0f;
			break;
		default:
			scale = 1.0f;
			break;
		}
		valueOut *= scale;
	}

	return valueOut;
}

static float apply_value_slope(const float value, const SDicomImage &dicomImage)
{
	return (value * dicomImage.mRescaleSlope) + dicomImage.mRescaleIntercept;
}

static float apply_value_sbp(const float value)
{	return powf((g_dicomOpts->mSBPBias + value) * g_dicomOpts->mSBPScale,
				g_dicomOpts->mSBPExponent);
}

static void convert_dicom_image(CArrayList<noesisTex_t *> &texturesOut,
								const SDicomImage &dicomImage, const EDicomTransferSyntax transferSyntax, noeRAPI_t *rapi)
{
	if (!dicomImage.mpData || dicomImage.mDataLength <= 0 ||
		dicomImage.mDataVR == skVR_Invalid || dicomImage.mBitsPerChannel <= 0)
	{
		rapi->LogOutput("WARNING: Invalid image data/size, discarding.\n");
		return;
	}
	if (dicomImage.mRowCount <= 0 || dicomImage.mColumnCount <= 0)
	{
		rapi->LogOutput("WARNING: Invalid image dimensions, discarding.\n");
		return;
	}	const int width = dicomImage.mColumnCount;
	const int height = dicomImage.mRowCount;
	const int sliceCount = std::max<int>(dicomImage.mSliceCount, 1);

	const bool applySlope = (g_dicomOpts && g_dicomOpts->mApplySlope);
	const bool applySBP = (g_dicomOpts && g_dicomOpts->mApplySBP);
	const bool dataNormalize = (g_dicomOpts && g_dicomOpts->mDataNormalize);

	RichBitStreamEx bs(dicomImage.mpData, dicomImage.mDataLength);
	for (int sliceIndex = 0; sliceIndex < sliceCount; ++sliceIndex)
	{
		unsigned char *pConvertedRgb = NULL;
		float *pConvertedFloat = NULL;
		ENoeHdrTexFormat convertedFloatFormat;
		bool convertedHasAlpha = false;
		bool isColor = false;
		bool expectJpeg = false;

		switch (dicomImage.mPhotometricInterpretation)
		{		case kDPI_YBR_Full:
		case kDPI_YBR_Full_422:
		case kDPI_YBR_Partial_422:
		case kDPI_YBR_Partial_420:
		case kDPI_YBR_ICT:
		case kDPI_YBR_RCT:
			expectJpeg = true;		case kDPI_RGB:
			isColor = true;		case kDPI_Monochrome1:
		case kDPI_Monochrome2:
			{
				if (expectJpeg && !is_jpeg_transfer_syntax(transferSyntax))
				{
					rapi->LogOutput("WARNING: Photometric interpretation not supported for transfer syntax.\n");
					break;
				}
				const int channelsPerPixel = (isColor) ? 3 : 1;
				convertedFloatFormat = (isColor) ? kNHDRTF_RGB_F96 : kNHDRTF_Lum_F32;
				pConvertedFloat = (float *)rapi->Noesis_UnpooledAlloc(width * height * sizeof(float) * channelsPerPixel);
				pConvertedRgb = (unsigned char *)rapi->Noesis_UnpooledAlloc(width * height * 3);
				float minSampleVal = FLT_MAX;
				float maxSampleVal = -FLT_MAX;				const bool planarMode = (dicomImage.mPlanarConfiguration != 0);
				const int channelsOuterLoop = (planarMode) ? channelsPerPixel : 1;
				const int channelsInnerLoop = (!planarMode) ? channelsPerPixel : 1;
				for (int channelIndexOuter = 0; channelIndexOuter < channelsOuterLoop; ++channelIndexOuter)
				{
					for (int y = 0; y < height; ++y)
					{
						for (int x = 0; x < width; ++x)
						{
							const int pixelIndex = y * width + x;
							for (int channelIndexInner = 0; channelIndexInner < channelsInnerLoop; ++channelIndexInner)
							{
								float &destFloat = pConvertedFloat[pixelIndex * channelsPerPixel +
																	channelIndexInner + channelIndexOuter];
								if (dicomImage.mDataVR == skVR_OtherWord &&
									dicomImage.mBitsPerChannel > 0)
								{									destFloat = (float)bs.ReadBits(dicomImage.mBitsPerChannel);
								}
								else
								{
									destFloat = read_single_element_value_for_vr<float>(bs, dicomImage.mDataVR, 0);
								}

								if (dataNormalize)
								{
									destFloat = normalize_value_for_image_data(destFloat, dicomImage);
								}
								if (applySlope)
								{
									destFloat = apply_value_slope(destFloat, dicomImage);
								}
								if (applySBP)
								{
									destFloat = apply_value_sbp(destFloat);
								}

								minSampleVal = (destFloat < minSampleVal) ? destFloat : minSampleVal;
								maxSampleVal = (destFloat > maxSampleVal) ? destFloat : maxSampleVal;
							}
						}
					}
				}				if (minSampleVal >= maxSampleVal)
				{
					minSampleVal = 0.0f;
					maxSampleVal = 1.0f;
				}
				converted_float_to_rgb(pConvertedRgb, 3, width, height, pConvertedFloat, channelsPerPixel,
										dicomImage.mDataVR, minSampleVal, maxSampleVal);
			}
			break;
		case kDPI_PaletteColor:
			{
				const SDicomPalette *pPalettes = dicomImage.mPaletteRgba;
				if (pPalettes[0].mpData && pPalettes[0].mBitsPerEntry > 0 && pPalettes[0].mEntryCount > 0 &&
					pPalettes[1].mpData && pPalettes[1].mBitsPerEntry > 0 && pPalettes[1].mEntryCount > 0 &&
					pPalettes[2].mpData && pPalettes[2].mBitsPerEntry > 0 && pPalettes[2].mEntryCount > 0)
				{
					const bool alphaIsValid = (pPalettes[3].mpData && pPalettes[3].mBitsPerEntry > 0 &&
												pPalettes[3].mEntryCount > 0);
					float *pPaletteColors[4] =
					{
						(float *)rapi->Noesis_UnpooledAlloc(sizeof(float) * pPalettes[0].mEntryCount),
						(float *)rapi->Noesis_UnpooledAlloc(sizeof(float) * pPalettes[1].mEntryCount),
						(float *)rapi->Noesis_UnpooledAlloc(sizeof(float) * pPalettes[2].mEntryCount),
						alphaIsValid ? (float *)rapi->Noesis_UnpooledAlloc(sizeof(float) * pPalettes[3].mEntryCount) : NULL
					};					for (int paletteIndex = 0; paletteIndex < 4; ++paletteIndex)
					{
						float *pPaletteDst = pPaletteColors[paletteIndex];
						if (pPaletteDst)
						{
							const SDicomPalette *pPalette = pPalettes + paletteIndex;							const float colorScale = (pPalette->mBitsPerEntry >= 16) ? 1.0f / 65535.0f : 1.0f / 255.0f;
							RichBitStreamEx palBs(pPalette->mpData, pPalette->mDataLength);
							for (unsigned int entryIndex = 0; entryIndex < pPalette->mEntryCount; ++entryIndex)
							{
								float &destFloat = pPaletteDst[entryIndex];
								destFloat = read_single_element_value_for_vr<float>(palBs, pPalette->mDataVR, 0) *
												colorScale;								if (applySlope)
								{
									destFloat = apply_value_slope(destFloat, dicomImage);
								}
								if (applySBP)
								{
									destFloat = apply_value_sbp(destFloat);
								}
							}
						}
					}

					convertedFloatFormat = kNHDRTF_RGBA_F128;
					convertedHasAlpha = true;
					pConvertedFloat = (float *)rapi->Noesis_UnpooledAlloc(width * height * sizeof(float) * 4);
					pConvertedRgb = (unsigned char *)rapi->Noesis_UnpooledAlloc(width * height * 4);					const bool ushortPixels = (dicomImage.mDataLength == (width * height * 2));
					for (int y = 0; y < height; ++y)
					{
						for (int x = 0; x < width; ++x)
						{
							float *pDestPixel = pConvertedFloat + (y * width + x) * 4;
							const int palEntryIndex = (dicomImage.mBitsPerChannel > 0) ?
															bs.ReadBits(dicomImage.mBitsPerChannel) :
															(ushortPixels) ? bs.ReadUShort() : bs.ReadByte();
							for (int paletteIndex = 0; paletteIndex < 4; ++paletteIndex)
							{
								const float *pPaletteFloat = pPaletteColors[paletteIndex];
								if (pPaletteFloat)
								{
									const SDicomPalette *pPalette = pPalettes + paletteIndex;
									int clampedPalEntryIndex = std::max<int>(palEntryIndex, pPalette->mFirstMappedEntry);
									clampedPalEntryIndex = std::min<int>(clampedPalEntryIndex, pPalette->mEntryCount - 1);
									pDestPixel[paletteIndex] = pPaletteFloat[clampedPalEntryIndex];
								}
								else
								{
									pDestPixel[paletteIndex] = 1.0f;
								}
							}
						}
					}

					rapi->Noesis_UnpooledFree(pPaletteColors[0]);
					rapi->Noesis_UnpooledFree(pPaletteColors[1]);
					rapi->Noesis_UnpooledFree(pPaletteColors[2]);
					if (pPaletteColors[3])
					{
						rapi->Noesis_UnpooledFree(pPaletteColors[3]);
					}					const float minSampleVal = 0.0f;
					const float maxSampleVal = 1.0f;
					converted_float_to_rgb(pConvertedRgb, 4, width, height, pConvertedFloat, 4, pPalettes->mDataVR,
											minSampleVal, maxSampleVal);
				}
				else
				{
					rapi->LogOutput("WARNING: Photometric interpretation is %s, but we're missing palette data.\n",
						skPhotometricInterpretationStrings[dicomImage.mPhotometricInterpretation]);
				}
			}
			break;
		default:
			rapi->LogOutput("WARNING: Photometric interpretation not currently supported: %s\n",
				skPhotometricInterpretationStrings[dicomImage.mPhotometricInterpretation]);
			break;
		}

		if (!pConvertedRgb)
		{
			break;
		}

		char sliceName[512];
		sprintf_s(sliceName, "image%04i", texturesOut.Num());
		const int colorChannelCount = (convertedHasAlpha) ? 4 : 3;
		noesisTex_t *pTex = rapi->Noesis_TextureAllocEx(sliceName, width, height, pConvertedRgb,
														width * height * colorChannelCount,
														(convertedHasAlpha) ? NOESISTEX_RGBA32 : NOESISTEX_RGB24, 0, 1);
		if (pConvertedFloat)
		{
			int floatChannelCount;
			switch (convertedFloatFormat)
			{
			case kNHDRTF_RGB_F96:
				floatChannelCount = 3;
				break;
			case kNHDRTF_RGBA_F128:
				floatChannelCount = 4;
				break;
			case kNHDRTF_Lum_F32:
			default:
				floatChannelCount = 1;
				break;
			}

			if (g_dicomOpts && g_dicomOpts->mFloatNormalize)
			{				float maxValue = 0.0f;
				for (int valueIndex = 0; valueIndex < width * height * floatChannelCount; ++valueIndex)
				{
					const float v = pConvertedFloat[valueIndex];
					maxValue = (v > maxValue) ? v : maxValue;
				}
				if (maxValue > 0.0f)
				{
					const float invMaxValue = 1.0f / maxValue;
					for (int valueIndex = 0; valueIndex < width * height * floatChannelCount; ++valueIndex)
					{
						pConvertedFloat[valueIndex] *= invMaxValue;
					}
				}
			}

			pTex->pHdr = rapi->Noesis_AllocHDRTexStructure(pConvertedFloat,
															width * height * sizeof(float) * floatChannelCount,
															convertedFloatFormat, NULL, NULL);
		}
		pTex->shouldFreeData = true;
		texturesOut.Append(pTex);
	}
}

static unsigned short *jpeg_decode_ls(const void *pSource, const int sourceSize,
										const int dataPrecision, const SDicomImage &dicomImage, noeRAPI_t *rapi,
										int *pWidthOut, int *pHeightOut, int *pComponentsOut, int *pPrecisionOut)
{
	JlsParameters params;
	if (JpegLsReadHeader(pSource, sourceSize, &params) != OK)
	{
		return NULL;
	}

	const int destSize = params.bytesperline * params.height;
	unsigned short *pDest = (unsigned short *)rapi->Noesis_UnpooledAlloc(destSize);	params.bytesperline = sizeof(unsigned short) * params.width;
	params.bitspersample = 16;
	if (JpegLsDecode(pDest, destSize, pSource, sourceSize, &params) != OK)
	{
		rapi->Noesis_UnpooledFree(pDest);
		return NULL;
	}

	*pWidthOut = params.width;
	*pHeightOut = params.height;
	*pComponentsOut = params.components;
	*pPrecisionOut = params.bitspersample;
	return pDest;
}

static void decode_jpeg_to_stream(RichBitStreamEx &bsJpegConcat, RichBitStreamEx &bsTotalOut,
									const SDicomImage &dicomImage, const EDicomTransferSyntax transferSyntax,
									noeRAPI_t *rapi)
{
	const int jpegSize = bsJpegConcat.GetOffset();
	if (jpegSize > 0)
	{
		int width, height, components, decodedPrecision;
		const int dataPrecision = (dicomImage.mBitsStoredPerChannel > 0) ? dicomImage.mBitsStoredPerChannel : 8;

		unsigned short *pDecoded;
		switch (transferSyntax)
		{
		case kDTS_JpegLSLossless:
		case kDTS_JpegLSNearLossless:
			pDecoded = jpeg_decode_ls((const unsigned char *)bsJpegConcat.GetBuffer(),
										jpegSize, dataPrecision, dicomImage, rapi,
										&width, &height, &components, &decodedPrecision);
			break;
		case kDTS_Jpeg2000LosslessReversible:
		case kDTS_Jpeg2000LosslessOrLossy:
		case kDTS_Jpeg2000Part2LosslessReversible:
		case kDTS_Jpeg2000Part2LosslessOrLossy:
			pDecoded = Image_JPEG2000_ReadDirectU16((const unsigned char *)bsJpegConcat.GetBuffer(),
										jpegSize,  &width, &height, &components, &decodedPrecision, rapi);
			break;
		default:
			pDecoded = rapi->Image_JPEG_ReadDirect((const unsigned char *)bsJpegConcat.GetBuffer(),
													jpegSize, dataPrecision, &width, &height, &components,
													&decodedPrecision, NULL);
			break;
		}

		if (pDecoded)
		{
			if (dataPrecision != decodedPrecision)
			{
				rapi->LogOutput("WARNING: DICOM stored bits per channel != JPEG data precision: %i vs %i\n",
					dataPrecision, decodedPrecision);
			}

			const int pixelCount = width * height * components;			const int shiftValue = (dicomImage.mBitsPerChannel - decodedPrecision);
			for (int pixelIndex = 0; pixelIndex < pixelCount; ++pixelIndex)
			{
				int pixelValue = pDecoded[pixelIndex];
				if (shiftValue > 0)
				{
					pixelValue <<= shiftValue;
				}
				else
				{
					pixelValue >>= (-shiftValue);
				}

				bsTotalOut.WriteBits(pixelValue, dicomImage.mBitsPerChannel);
			}
			rapi->Noesis_UnpooledFree(pDecoded);
		}

		bsJpegConcat.SetOffset(0);
	}
}

static unsigned char *decompress_jpeg(int *pSizeOut, const unsigned char *pData, const SDicomImage &dicomImage,
										const EDicomTransferSyntax transferSyntax, const int maxDataSize, noeRAPI_t *rapi)
{	RichBitStreamEx bsTotalOut;
	RichBitStreamEx bsJpegConcat;
	RichBitStreamEx bs((void *)pData, maxDataSize);
	unsigned int delimiter = bs.ReadUInt();
	bool firstSeg = true;
	const int *pFrameOffsets = NULL;
	int frameCount = 0;
	int currentFrame = 0;
	int baseOfs = 0;
	while (delimiter == skSequenceTag && bs.GetOffset() < bs.GetSize())
	{
		const int seqSegSize = bs.ReadInt();
		const int jpegHeaderOfs = bs.GetOffset();
		if (seqSegSize > 0)
		{
			if (firstSeg)
			{
				pFrameOffsets = (const int *)((const char *)bs.GetBuffer() + jpegHeaderOfs);
				frameCount = seqSegSize / sizeof(int);
				baseOfs = jpegHeaderOfs + seqSegSize + 8;
			}
			else
			{
				if (frameCount > 0 && currentFrame < frameCount)
				{					int currentOfs = jpegHeaderOfs - baseOfs;
					if (pFrameOffsets[currentFrame] >= currentOfs)
					{						decode_jpeg_to_stream(bsJpegConcat, bsTotalOut, dicomImage, transferSyntax, rapi);
						++currentFrame;
					}
				}
				const unsigned char *pJpegData = (const unsigned char *)bs.GetBuffer() + jpegHeaderOfs;
				bsJpegConcat.WriteBytes(pJpegData, seqSegSize);
			}
		}
		firstSeg = false;

		bs.SetOffset(jpegHeaderOfs + seqSegSize);
		delimiter = bs.ReadUInt();
	}	decode_jpeg_to_stream(bsJpegConcat, bsTotalOut, dicomImage, transferSyntax, rapi);

	const int outSize = bsTotalOut.GetOffset();
	if (outSize <= 0)
	{
		return NULL;
	}

	*pSizeOut = outSize;
	unsigned char *pOutBuffer = (unsigned char *)rapi->Noesis_UnpooledAlloc(outSize);
	memcpy(pOutBuffer, bsTotalOut.GetBuffer(), outSize);
	return pOutBuffer;
}static unsigned char *decompress_rle(int *pSizeOut, const unsigned char *pData, const int maxDataSize,
										const int bitsPerChannel, noeRAPI_t *rapi)
{
	RichBitStreamEx bsOut;
	RichBitStreamEx bs((void *)pData, maxDataSize);
	unsigned int delimiter = bs.ReadUInt();
	while (delimiter == skSequenceTag && bs.GetOffset() < bs.GetSize())
	{
		const unsigned int seqSegSize = bs.ReadUInt();
		const int rleHeaderOfs = bs.GetOffset();
		const int dataOutOfs = bsOut.GetOffset();

		int segCount = bs.ReadInt();
		const unsigned int *pSegOffsets = (const unsigned int *)((unsigned char *)bs.GetBuffer() + bs.GetOffset());
		for (int segIndex = 0; segIndex < segCount; ++segIndex)
		{
			const int segEnd = (segIndex >= (segCount - 1) || pSegOffsets[segIndex + 1] < pSegOffsets[segIndex]) ?
								rleHeaderOfs + seqSegSize : rleHeaderOfs + pSegOffsets[segIndex + 1];
			bs.SetOffset(rleHeaderOfs + pSegOffsets[segIndex]);
			while (bs.GetOffset() < segEnd)
			{
				const char n = bs.ReadChar();
				if (n >= 0)
				{
					const int repCount = n + 1;
					for (int valueIndex = 0; valueIndex < repCount && bs.GetOffset() < segEnd; ++valueIndex)
					{
						bsOut.WriteByte(bs.ReadByte());
					}
				}
				else if (n >= -127 && bs.GetOffset() < segEnd)
				{
					const unsigned char rep = bs.ReadByte();
					const int repCount = -n + 1;
					for (int valueIndex = 0; valueIndex < repCount; ++valueIndex)
					{
						bsOut.WriteByte(rep);
					}
				}
			}
		}
		if (segCount > 1)
		{			const unsigned int flatDataSize = bsOut.GetOffset() - dataOutOfs;
			unsigned char *pFlatData = (unsigned char *)bsOut.GetBuffer() + dataOutOfs;
			unsigned char *pTempBuffer = (unsigned char *)rapi->Noesis_UnpooledAlloc(flatDataSize + segCount);
			unsigned char *pTempChannels = pTempBuffer + flatDataSize;
			const int interleavedPixelCount = flatDataSize / segCount;			const int bytesPerChannel = bitsPerChannel / 8;			for (int pixelIndex = 0; pixelIndex < interleavedPixelCount; ++pixelIndex)
			{				for (int channelIndex = 0; channelIndex < segCount; ++channelIndex)
				{
					pTempBuffer[pixelIndex * segCount + channelIndex] =
						pFlatData[pixelIndex + channelIndex * interleavedPixelCount];
				}				if (bytesPerChannel > 1)
				{
					unsigned char *pInterleavedPixel = pTempBuffer + pixelIndex * segCount;
					for (int channelIndex = 0; channelIndex < segCount; channelIndex += bytesPerChannel)
					{
						for (int channelByteIndex = 0; channelByteIndex < bytesPerChannel; ++channelByteIndex)
						{
							pTempChannels[channelIndex + channelByteIndex] =
								pInterleavedPixel[channelIndex + (bytesPerChannel - channelByteIndex - 1)];
						}
					}
					memcpy(pInterleavedPixel, pTempChannels, segCount);
				}
			}			memcpy(pFlatData, pTempBuffer, flatDataSize);
			rapi->Noesis_UnpooledFree(pTempBuffer);
		}

		bs.SetOffset(rleHeaderOfs + seqSegSize);
		delimiter = bs.ReadUInt();
	}

	const int outSize = bsOut.GetOffset();
	if (outSize <= 0)
	{
		return NULL;
	}

	*pSizeOut = outSize;
	unsigned char *pOutBuffer = (unsigned char *)rapi->Noesis_UnpooledAlloc(outSize);
	memcpy(pOutBuffer, bsOut.GetBuffer(), outSize);
	return pOutBuffer;
}

static void set_palette_data_from_element(SDicomPalette *pPalette, RichBitStreamEx &bs, const CDicomDataElement &elem)
{
	pPalette->mpData = (unsigned char *)bs.GetBuffer() + elem.GetValueOfs();
	pPalette->mDataLength = elem.GetValueLength();
	pPalette->mDataVR = elem.GetVR();
}

static void set_palette_descriptor_from_element(SDicomPalette *pPalette, RichBitStreamEx &bs,
												const EDicomTransferSyntax transferSyntax, const CDicomDataElement &elem)
{
	elem.ReadArrayElementValues<unsigned int>(pPalette->mDescriptor, 3, bs, transferSyntax);
	if (pPalette->mEntryCount == 0)
	{		pPalette->mEntryCount = 65536;
	}
}

bool Image_MRI_LoadDicom(BYTE *fileBuffer, int bufferLen, CArrayList<noesisTex_t *> &noeTex, noeRAPI_t *rapi)
{
	RichBitStreamEx bs(fileBuffer, bufferLen);
	bs.SetOffset(skDataElemsOffset);

	bool transferSyntaxSupported;
	const EDicomTransferSyntax transferSyntax = find_transfer_syntax(bs);
	switch (transferSyntax)
	{
	case kDTS_ImplicitVRLittleEndian:
	case kDTS_ExplicitVRLittleEndian:
	case kDTS_ExplicitVRBigEndian:
	case kDTS_RLE:
	case kDTS_JpegBaseline:
	case kDTS_JpegExtended:
	case kDTS_JpegSpectral:
	case kDTS_JpegProgressive:
	case kDTS_JpegLossless:
	case kDTS_JpegLosslessFirstOrder:
	case kDTS_JpegLSLossless:
	case kDTS_JpegLSNearLossless:
	case kDTS_Jpeg2000LosslessReversible:
	case kDTS_Jpeg2000LosslessOrLossy:
	case kDTS_Jpeg2000Part2LosslessReversible:
	case kDTS_Jpeg2000Part2LosslessOrLossy:
		transferSyntaxSupported = true;
		break;
	default:
		transferSyntaxSupported = false;
		break;
	}

	if (!transferSyntaxSupported)
	{
		rapi->LogOutput("The following DICOM transfer syntax is not currently supported: %s\n",
			skTransferSyntaxStrings[transferSyntax]);
		return NULL;
	}

	rapi->LogOutput("Parsing data elements with transfer syntax %s.\n", skTransferSyntaxStrings[transferSyntax]);

	const int logDataElements = (g_dicomOpts) ? g_dicomOpts->mLogDataElements : 0;
	if (logDataElements > 0)
	{		bs.SetOffset(skDataElemsOffset);
	}

	int dataElementCount = 0;
	SDicomImage currentImage;	while (bs.GetOffset() < bs.GetSize())
	{
		const CDicomDataElement elem(bs, transferSyntax);

		if (logDataElements > 0)
		{
			const unsigned short vr = elem.GetVR();
			const char *pVR = (vr != 0) ? (const char *)&vr : "NA";
			rapi->LogOutput("%04i - Data Element (%04x,%04x) - VR: %c%c Size: %i Offset: %i\n", dataElementCount,
				elem.GetGroupNum(), elem.GetElemNum(), pVR[0], pVR[1], elem.GetValueLength(), elem.GetValueOfs());
			if (logDataElements > 1)
			{				rapi->LogOutput("	Value: ");
				switch (elem.GetVR())
				{
				case skVR_ApplicationEntity:
				case skVR_AgeString:
				case skVR_CodeString:
				case skVR_Date:
				case skVR_DecimalString:
				case skVR_DateTime:
				case skVR_IntString:
				case skVR_LongString:
				case skVR_LongText:
				case skVR_PersonName:
				case skVR_ShortString:
				case skVR_ShortText:
				case skVR_Time:
				case skVR_UID:
					{
						const char *pTempBuffer = elem.TemporaryStringForElementValue(bs);
						rapi->LogOutput("%s", (pTempBuffer) ? pTempBuffer : "Unknown"); 
					}
					break;
				case skVR_AttributeTag:
					{
						unsigned short tagValues[2];
						elem.ReadArrayElementValues<unsigned short>(tagValues, 2, bs, transferSyntax);
						rapi->LogOutput("(%04x,%04x)", tagValues[0], tagValues[1]); 
					}
					break;
				case skVR_Float:
				case skVR_Double:
					{
						const double value = elem.ReadSingleElementValue<double>(bs, transferSyntax);
						rapi->LogOutput("%f", value);
					}
					break;
				case skVR_SignedLong:
				case skVR_SignedShort:
					{
						const int value = elem.ReadSingleElementValue<int>(bs, transferSyntax);
						rapi->LogOutput("%i", value);
					}
					break;
				case skVR_UnsignedLong:
				case skVR_UnsignedShort:
					{
						const unsigned int value = elem.ReadSingleElementValue<unsigned int>(bs, transferSyntax);
						rapi->LogOutput("%i", value);
					}
					break;
				case skVR_OtherByte:
				case skVR_OtherFloat:
				case skVR_OtherWord:
				case skVR_Sequence:
					rapi->LogOutput("...");
					break;
				default:
					rapi->LogOutput("N/A");
					break;
				}
				rapi->LogOutput("\n");
			}
		}

		switch (elem.GetElementId())
		{
		case skPixelDataElement:
			{
				unsigned char *pTempBuffer = NULL;
				int decompressedSize = 0;
				currentImage.mpData = (unsigned char *)bs.GetBuffer() + elem.GetValueOfs();
				currentImage.mDataLength = elem.GetValueLength();
				currentImage.mDataVR = elem.GetVR();

				bool convertVR = false;
				switch (transferSyntax)
				{
				case kDTS_RLE:
					pTempBuffer = decompress_rle(&decompressedSize, currentImage.mpData, bs.GetSize() - elem.GetValueOfs(),
													currentImage.mBitsPerChannel, rapi);
					convertVR = true;
					break;
				case kDTS_JpegBaseline:
				case kDTS_JpegExtended:
				case kDTS_JpegSpectral:
				case kDTS_JpegProgressive:
				case kDTS_JpegLossless:
				case kDTS_JpegLosslessFirstOrder:
				case kDTS_JpegLSLossless:
				case kDTS_JpegLSNearLossless:
				case kDTS_Jpeg2000LosslessReversible:
				case kDTS_Jpeg2000LosslessOrLossy:
				case kDTS_Jpeg2000Part2LosslessReversible:
				case kDTS_Jpeg2000Part2LosslessOrLossy:
					pTempBuffer = decompress_jpeg(&decompressedSize, currentImage.mpData, currentImage, transferSyntax,
													bs.GetSize() - elem.GetValueOfs(), rapi);
					convertVR = true;
					break;
				default:
					break;
				}

				if (pTempBuffer && decompressedSize > 0)
				{					currentImage.mpData = pTempBuffer;
					currentImage.mDataLength = decompressedSize;
				}

				if (convertVR && currentImage.mBitsPerChannel > 0)
				{					if (currentImage.mBitsPerChannel >= 32)
					{
						currentImage.mDataVR = skVR_OtherFloat;
					}
					else if (currentImage.mBitsPerChannel != 8)
					{
						currentImage.mDataVR = skVR_OtherWord;
					}
					else
					{
						currentImage.mDataVR = skVR_OtherByte;
					}
				}				if (currentImage.mPhotometricInterpretation == kDPI_Unknown &&
					currentImage.mBitsPerChannel > 0 && currentImage.mDataLength > 0)
				{
					const int sliceCount = std::max<int>(currentImage.mSliceCount, 1);
					const int pixelCount = currentImage.mColumnCount * currentImage.mRowCount * sliceCount;
					const int pixelBitsForOneChannel = pixelCount * currentImage.mBitsPerChannel;
					const int channelCount = (currentImage.mDataLength * 8) / pixelBitsForOneChannel;
					switch (channelCount)
					{
					case 1:
						currentImage.mPhotometricInterpretation = kDPI_Monochrome2;
						break;
					case 3:
						currentImage.mPhotometricInterpretation = kDPI_RGB;
						break;
					default:						break;
					}
				}				convert_dicom_image(noeTex, currentImage, transferSyntax, rapi);
				currentImage = SDicomImage();
				if (pTempBuffer)
				{
					rapi->Noesis_UnpooledFree(pTempBuffer);
				}
			}
			break;
		case skPixelDataPlanarConfigurationElement:
			currentImage.mPlanarConfiguration = elem.ReadSingleElementValue<int>(bs, transferSyntax);
			break;
		case skPixelDataSamplesPerPixelElement:
			currentImage.mSamplesPerPixel = elem.ReadSingleElementValue<int>(bs, transferSyntax);
			break;
		case skPixelDataBitsAllocatedElement:
			currentImage.mBitsPerChannel = elem.ReadSingleElementValue<int>(bs, transferSyntax);
			break;
		case skPixelDataBitsStoredElement:
			currentImage.mBitsStoredPerChannel = elem.ReadSingleElementValue<int>(bs, transferSyntax);
			break;
		case skPixelDataHighBitElement:
			currentImage.mHighBit = elem.ReadSingleElementValue<int>(bs, transferSyntax);
			break;
		case skPixelDataPhotometricInterpretationElement:
			{
				elem.PrepDataStreamForValueRead(bs, transferSyntax);
				const char *pTempBuffer = elem.TemporaryStringForElementValue(bs);
				currentImage.mPhotometricInterpretation = photometric_interpretation_for_string(pTempBuffer);
			}
			break;
		case skPixelDataRowsElement:
			currentImage.mRowCount = elem.ReadSingleElementValue<int>(bs, transferSyntax);
			break;
		case skPixelDataColumnsElement:
			currentImage.mColumnCount = elem.ReadSingleElementValue<int>(bs, transferSyntax);
			break;
		case skPixelDataFrameCountElement:
			currentImage.mSliceCount = elem.ReadSingleElementValue<int>(bs, transferSyntax);
			break;
		case skPixelDataRescaleIntercept:
			currentImage.mRescaleIntercept = elem.ReadSingleElementValue<float>(bs, transferSyntax);
			break;
		case skPixelDataRescaleSlope:
			currentImage.mRescaleSlope = elem.ReadSingleElementValue<float>(bs, transferSyntax);
			break;

		case skRedPaletteLookupTableDescElement:
			set_palette_descriptor_from_element(&currentImage.mPaletteRgba[0], bs, transferSyntax, elem);
			break;
		case skGreenPaletteLookupTableDescElement:
			set_palette_descriptor_from_element(&currentImage.mPaletteRgba[1], bs, transferSyntax, elem);
			break;
		case skBluePaletteLookupTableDescElement:
			set_palette_descriptor_from_element(&currentImage.mPaletteRgba[2], bs, transferSyntax, elem);
			break;
		case skAlphaPaletteLookupTableDescElement:
			set_palette_descriptor_from_element(&currentImage.mPaletteRgba[3], bs, transferSyntax, elem);
			break;
		case skRedPaletteLookupTableDataElement:
			set_palette_data_from_element(&currentImage.mPaletteRgba[0], bs, elem);
			break;
		case skGreenPaletteLookupTableDataElement:
			set_palette_data_from_element(&currentImage.mPaletteRgba[1], bs, elem);
			break;
		case skBluePaletteLookupTableDataElement:
			set_palette_data_from_element(&currentImage.mPaletteRgba[2], bs, elem);
			break;
		case skAlphaPaletteLookupTableDataElement:
			set_palette_data_from_element(&currentImage.mPaletteRgba[3], bs, elem);
			break;

		default:
			break;
		}

		++dataElementCount;
		elem.SetStreamToNextDataElement(bs);
	}

	if (logDataElements > 0)
	{
		rapi->LogOutput("Data Element count (may include sequence delimiters): %i\n", dataElementCount);
	}

	return true;
}

static void flush_group_stream(const unsigned short groupNum, const EDicomTransferSyntax outTS,
								RichBitStreamEx &outStream, RichBitStreamEx &groupStream)
{	CDicomDataElement(groupNum, 0x0000, skVR_UnsignedLong).WriteTypeToStream<unsigned int>(
		outStream, outTS, groupStream.GetOffset());	outStream.WriteBytes(groupStream.GetBuffer(), groupStream.GetOffset());

	groupStream.SetOffset(0);
}

bool Image_MRI_SaveDicom(char *fileName, noesisTex_t *textures, int numTex, noeRAPI_t *rapi)
{	RichBitStreamEx outStream;

	RichBitStreamEx groupStream;

	const int width = textures->w;
	const int height = textures->h;	const EDicomTransferSyntax outTS = kDTS_ExplicitVRLittleEndian;

	rapi->LogOutput("Exporting DICOM with transfer syntax %s...\n",
		skTransferSyntaxStrings[outTS]);

	for (int preambleIndex = 0; preambleIndex < skHeaderOffset; ++preambleIndex)
	{
		outStream.WriteByte(0);
	}
	outStream.WriteString("DICM");

	unsigned char metaVerData[2] = { 0x00, 0x01 };	CDicomDataElement(skGroup2, 0x0001, skVR_OtherByte).WriteToStream(
		groupStream, outTS, metaVerData, sizeof(metaVerData));	CDicomDataElement(skGroup2, 0x0002, skVR_UID).WriteStringToStream(
		groupStream, outTS, "1.2.840.10008.5.1.4.1.1.6");	CDicomDataElement(skGroup2, 0x0003, skVR_UID).WriteStringToStream(
		groupStream, outTS, "999.999.2.20150101.112000.2.666");	CDicomDataElement(skGroup2, 0x0010, skVR_UID).WriteStringToStream(
		groupStream, outTS, skTransferSyntaxStrings[outTS]);	CDicomDataElement(skGroup2, 0x0012, skVR_UID).WriteStringToStream(
		groupStream, outTS, "999.999");	flush_group_stream(skGroup2, outTS, outStream, groupStream);	CDicomDataElement(0x0008, 0x0008, skVR_CodeString).WriteStringToStream(
		groupStream, outTS, "ORIGINAL\\PRIMARY");	CDicomDataElement(0x0008, 0x0016, skVR_UID).WriteStringToStream(
		groupStream, outTS, "1.2.840.10008.5.1.4.1.1.6");	CDicomDataElement(0x0008, 0x0018, skVR_UID).WriteStringToStream(
		groupStream, outTS, "999.999.2.20150101.112000.2.666");	CDicomDataElement(0x0008, 0x0020, skVR_Date).WriteStringToStream(
		groupStream, outTS, "2015.01.01");	CDicomDataElement(0x0008, 0x0023, skVR_Date).WriteStringToStream(
		groupStream, outTS, "2015.01.01");	CDicomDataElement(0x0008, 0x0030, skVR_Time).WriteStringToStream(
		groupStream, outTS, "10:00:00");	CDicomDataElement(0x0008, 0x0060, skVR_CodeString).WriteStringToStream(
		groupStream, outTS, "US");	CDicomDataElement(0x0008, 0x0070, skVR_LongString).WriteStringToStream(
		groupStream, outTS, "Noesis");	CDicomDataElement(0x0008, 0x0090, skVR_PersonName).WriteStringToStream(
		groupStream, outTS, "Whitehouse, Dick");	CDicomDataElement(0x0008, 0x1030, skVR_LongString).WriteStringToStream(
		groupStream, outTS, "Noesis export");	CDicomDataElement(0x0008, 0x103E, skVR_LongString).WriteStringToStream(
		groupStream, outTS, "Very important data");	CDicomDataElement(0x0008, 0x2120, skVR_LongString).WriteStringToStream(
		groupStream, outTS, "Happy lovely time");	CDicomDataElement(0x0008, 0x2122, skVR_IntString).WriteStringToStream(
		groupStream, outTS, "1");	CDicomDataElement(0x0008, 0x2124, skVR_IntString).WriteStringToStream(
		groupStream, outTS, "1");	CDicomDataElement(0x0008, 0x2128, skVR_IntString).WriteStringToStream(
		groupStream, outTS, "1");	CDicomDataElement(0x0008, 0x212A, skVR_IntString).WriteStringToStream(
		groupStream, outTS, "1");	flush_group_stream(0x0008, outTS, outStream, groupStream);	CDicomDataElement(0x0010, 0x0010, skVR_PersonName).WriteStringToStream(
		groupStream, outTS, "Wong, Johnny");	flush_group_stream(0x0010, outTS, outStream, groupStream);	CDicomDataElement(0x0018, 0x1030, skVR_LongString).WriteStringToStream(
		groupStream, outTS, "Noesis Export");	if (numTex > 1)
	{
		CDicomDataElement(skFrameTimeElement, skVR_DecimalString).WriteStringToStream(
			groupStream, outTS, "33.333");
	}	flush_group_stream(0x0018, outTS, outStream, groupStream);	CDicomDataElement(0x0020, 0x000D, skVR_UID).WriteStringToStream(
		groupStream, outTS, "999.999.2.20150101.112000");	CDicomDataElement(0x0020, 0x000E, skVR_UID).WriteStringToStream(
		groupStream, outTS, "999.999.2.20150101.112000.2");	CDicomDataElement(0x0020, 0x0011, skVR_IntString).WriteStringToStream(
		groupStream, outTS, "2");	CDicomDataElement(0x0020, 0x0013, skVR_IntString).WriteStringToStream(
		groupStream, outTS, "666");	flush_group_stream(0x0020, outTS, outStream, groupStream);	CDicomDataElement(skPixelDataSamplesPerPixelElement, skVR_UnsignedShort).WriteTypeToStream<unsigned short>(
		groupStream, outTS, 3);	CDicomDataElement(skPixelDataPhotometricInterpretationElement, skVR_CodeString).WriteStringToStream(
		groupStream, outTS, skPhotometricInterpretationStrings[kDPI_RGB]);	CDicomDataElement(skPixelDataPlanarConfigurationElement, skVR_UnsignedShort).WriteTypeToStream<unsigned short>(
		groupStream, outTS, 0);	if (numTex > 1)
	{
		char tempString[256];
		sprintf_s(tempString, "%i", numTex);
		CDicomDataElement(skPixelDataFrameCountElement, skVR_IntString).WriteStringToStream(
			groupStream, outTS, tempString);
		CDicomDataElement(skPixelDataFrameIncrementPointerElement, skVR_AttributeTag).WriteTypeToStream<unsigned int>(
			groupStream, outTS, skFrameTimeElement);
	}	CDicomDataElement(skPixelDataRowsElement, skVR_UnsignedShort).WriteTypeToStream<unsigned short>(
		groupStream, outTS, height);	CDicomDataElement(skPixelDataColumnsElement, skVR_UnsignedShort).WriteTypeToStream<unsigned short>(
		groupStream, outTS, width);	CDicomDataElement(skPixelDataAspectRatioElement, skVR_IntString).WriteStringToStream(
		groupStream, outTS, "4\\3");	CDicomDataElement(skPixelDataBitsAllocatedElement, skVR_UnsignedShort).WriteTypeToStream<unsigned short>(
		groupStream, outTS, 8);	CDicomDataElement(skPixelDataBitsStoredElement, skVR_UnsignedShort).WriteTypeToStream<unsigned short>(
		groupStream, outTS, 8);	CDicomDataElement(skPixelDataHighBitElement, skVR_UnsignedShort).WriteTypeToStream<unsigned short>(
		groupStream, outTS, 7);	CDicomDataElement(skPixelDataRepresentationElement, skVR_UnsignedShort).WriteTypeToStream<unsigned short>(
		groupStream, outTS, 0);	flush_group_stream(0x0028, outTS, outStream, groupStream);	{
		RichBitStreamEx imageStream;
		for (int texIndex = 0; texIndex < numTex; ++texIndex)
		{
			noesisTex_t *pTexture = textures + texIndex;
			bool shouldFreeRgba = false;
			unsigned char *pRgba = rapi->Image_GetTexRGBA(pTexture, shouldFreeRgba);
			if (!pRgba)
			{
				rapi->LogOutput("WARNING: Could not retrieve RGBA data for texture %i.\n", texIndex);
				pRgba = (unsigned char *)rapi->Noesis_UnpooledAlloc(width * height * 4);
				memset(pRgba, 0, width * height * 4);
				shouldFreeRgba = true;
			}
			else
			{
				if (pTexture->w != width || pTexture->h != height)
				{					unsigned char *pResizedRgba = (unsigned char *)rapi->Noesis_UnpooledAlloc(width * height * 4);
					rapi->Noesis_ResampleImageBilinear(pRgba, pTexture->w, pTexture->h, pResizedRgba, width, height);
					if (shouldFreeRgba)
					{
						rapi->Noesis_UnpooledFree(pRgba);
					}					pRgba = pResizedRgba;
					shouldFreeRgba = true;
				}				for (int pixelIndex = 0; pixelIndex < width * height; ++pixelIndex)
				{
					const unsigned char *pColor = pRgba + pixelIndex * 4;
					imageStream.WriteByte(pColor[0]);
					imageStream.WriteByte(pColor[1]);
					imageStream.WriteByte(pColor[2]);
				}
			}

			if (shouldFreeRgba)
			{
				rapi->Noesis_UnpooledFree(pRgba);
			}
		}		CDicomDataElement(skPixelDataElement, skVR_OtherByte).WriteToStream(
			groupStream, outTS, imageStream.GetBuffer(), imageStream.GetOffset());
	}	flush_group_stream(0x7FE0, outTS, outStream, groupStream);

	const int finalSize = outStream.GetSize();
	rapi->Noesis_WriteFile(fileName, outStream.GetBuffer(), finalSize);

	return true;
}

#define DICOM_DECL_OPTS(argRequired) \
	dicomOpts_t *lopts = (dicomOpts_t *)store; \
	assert(storeSize == sizeof(dicomOpts_t)); \
	if (argRequired && !arg) \
	{ \
		return false; \
	}

bool Model_MRI_FloatNormalizeHandler(const char *arg, unsigned char *store, int storeSize)
{
	DICOM_DECL_OPTS(false);

	lopts->mFloatNormalize = true;
	return true;
}

bool Model_MRI_SBPHandler(const char *arg, unsigned char *store, int storeSize)
{
	DICOM_DECL_OPTS(true);

	lopts->mApplySBP = true;
	sscanf(arg, "%f;%f;%f", &lopts->mSBPScale, &lopts->mSBPBias, &lopts->mSBPExponent);
	return true;
}

bool Model_MRI_DataNormalizeHandler(const char *arg, unsigned char *store, int storeSize)
{
	DICOM_DECL_OPTS(false);

	lopts->mDataNormalize = true;
	return true;
}

bool Model_MRI_ApplySlopeHandler(const char *arg, unsigned char *store, int storeSize)
{
	DICOM_DECL_OPTS(false);

	lopts->mApplySlope = true;
	return true;
}

bool Model_MRI_ElemLogHandler(const char *arg, unsigned char *store, int storeSize)
{
	DICOM_DECL_OPTS(true);

	lopts->mLogDataElements = atoi(arg);
	return true;
}