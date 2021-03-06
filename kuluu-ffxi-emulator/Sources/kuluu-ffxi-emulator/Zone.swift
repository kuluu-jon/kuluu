public enum Zone: Int, CaseIterable {
    public static var current: Zone = Self.allCases.first!
    case unknown = 0
    case phanauetChannel = 1
    case carpentersLanding = 2
    case manaclipper = 3
    case bibikiBay = 4
    case uleguerandRange = 5
    case bearclawPinnacle = 6
    case attohwaChasm = 7
    case boneyardGully = 8
    case psoXja = 9
    case theShroudedMaw = 10
    case oldtonMovalpolos = 11
    case newtonMovalpolos = 12
    case mineShaft2716 = 13
    case hallOfTransference = 14
    case abysseaKonschtat = 15
    case promyvionHolla = 16
    case spireOfHolla = 17
    case promyvionDem = 18
    case spireOfDem = 19
    case promyvionMea = 20
    case spireOfMea = 21
    case promyvionVahzl = 22
    case spireOfVahzl = 23
    case lufaiseMeadows = 24
    case misareauxCoast = 25
    case tavnazianSafehold = 26
    case phomiunaAqueducts = 27
    case sacrarium = 28
    case riverneSiteB01 = 29
    case riverneSiteA01 = 30
    case monarchLinn = 31
    case sealionSDen = 32
    case alTaieu = 33
    case grandPalaceOfHuXzoi = 34
    case theGardenOfRuHmet = 35
    case empyrealParadox = 36
    case temenos = 37
    case apollyon = 38
    case dynamisValkurm = 39
    case dynamisBuburimu = 40
    case dynamisQufim = 41
    case dynamisTavnazia = 42
    case dioramaAbdhaljsGhelsba = 43
    case abdhaljsIslePurgonorgo = 44
    case abysseaTahrongi = 45
    case openSeaRouteToAlZahbi = 46
    case openSeaRouteToMhaura = 47
    case alZahbi = 48
    case none = 49
    case ahtUrhganWhitegate = 50
    case wajaomWoodlands = 51
    case bhaflauThickets = 52
    case nashmau = 53
    case arrapagoReef = 54
    case ilrusiAtoll = 55
    case periqia = 56
    case talaccaCove = 57
    case silverSeaRouteToNashmau = 58
    case silverSeaRouteToAlZahbi = 59
    case theAshuTalif = 60
    case mountZhayolm = 61
    case halvung = 62
    case lebrosCavern = 63
    case navukgoExecutionChamber = 64
    case mamook = 65
    case mamoolJaTrainingGrounds = 66
    case jadeSepulcher = 67
    case aydeewaSubterrane = 68
    case leujaoamSanctum = 69
    case chocoboCircuit = 70
    case theColosseum = 71
    case alzadaalUnderseaRuins = 72
    case zhayolmRemnants = 73
    case arrapagoRemnants = 74
    case bhaflauRemnants = 75
    case silverSeaRemnants = 76
    case nyzulIsle = 77
    case hazhalmTestingGrounds = 78
    case caedarvaMire = 79
    case southernSanDOriaS = 80
    case eastRonfaureS = 81
    case jugnerForestS = 82
    case vunkerlInletS = 83
    case batalliaDownsS = 84
    case laVauleS = 85
    case everbloomHollow = 86
    case bastokMarketsS = 87
    case northGustabergS = 88
    case graubergS = 89
    case pashhowMarshlandsS = 90
    case rolanberryFieldsS = 91
    case beadeauxS = 92
    case ruhotzSilvermines = 93
    case windurstWatersS = 94
    case westSarutabarutaS = 95
    case fortKarugoNarugoS = 96
    case meriphataudMountainsS = 97
    case sauromugueChampaignS = 98
    case castleOztrojaS = 99
    case westRonfaure = 100
    case eastRonfaure = 101
    case laTheinePlateau = 102
    case valkurmDunes = 103
    case jugnerForest = 104
    case batalliaDowns = 105
    case northGustaberg = 106
    case southGustaberg = 107
    case konschtatHighlands = 108
    case pashhowMarshlands = 109
    case rolanberryFields = 110
    case beaucedineGlacier = 111
    case xarcabard = 112
    case capeTeriggan = 113
    case easternAltepaDesert = 114
    case westSarutabaruta = 115
    case eastSarutabaruta = 116
    case tahrongiCanyon = 117
    case buburimuPeninsula = 118
    case meriphataudMountains = 119
    case sauromugueChampaign = 120
    case theSanctuaryOfZiTah = 121
    case roMaeve = 122
    case yuhtungaJungle = 123
    case yhoatorJungle = 124
    case westernAltepaDesert = 125
    case qufimIsland = 126
    case behemothSDominion = 127
    case valleyOfSorrows = 128
    case ghoyuSReverie = 129
    case ruAunGardens = 130
    case mordionGaol = 131
    case abysseaLaTheine = 132
    case lobby = 133
    case dynamisBeaucedine = 134
    case dynamisXarcabard = 135
    case beaucedineGlacierS = 136
    case xarcabardS = 137
    case castleZvahlBaileysS = 138
    case horlaisPeak = 139
    case ghelsbaOutpost = 140
    case fortGhelsba = 141
    case yughottGrotto = 142
    case palboroughMines = 143
    case waughroonShrine = 144
    case giddeus = 145
    case balgaSDais = 146
    case beadeaux = 147
    case qulunDome = 148
    case davoi = 149
    case monasticCavern = 150
    case castleOztroja = 151
    case altarRoom = 152
    case theBoyahdaTree = 153
    case dragonSAery = 154
    case castleZvahlKeepS = 155
    case throneRoomS = 156
    case middleDelkfuttSTower = 157
    case upperDelkfuttSTower = 158
    case templeOfUggalepih = 159
    case denOfRancor = 160
    case castleZvahlBaileys = 161
    case castleZvahlKeep = 162
    case sacrificialChamber = 163
    case garlaigeCitadelS = 164
    case throneRoom = 165
    case ranguemontPass = 166
    case bostaunieuxOubliette = 167
    case chamberOfOracles = 168
    case toraimaraiCanal = 169
    case fullMoonFountain = 170
    case crawlersNestS = 171
    case zeruhnMines = 172
    case korrolokaTunnel = 173
    case kuftalTunnel = 174
    case theEldiemeNecropolisS = 175
    case seaSerpentGrotto = 176
    case veLugannonPalace = 177
    case theShrineOfRuAvitau = 178
    case stellarFulcrum = 179
    case laLoffAmphitheater = 180
    case theCelestialNexus = 181
    case walkOfEchoes = 182
    case maquetteAbdhaljsLegionA = 183
    case lowerDelkfuttSTower = 184
    case dynamisSanDOria = 185
    case dynamisBastok = 186
    case dynamisWindurst = 187
    case dynamisJeuno = 188
    case residentialArea1 = 189
    case kingRanperreSTomb = 190
    case dangrufWadi = 191
    case innerHorutotoRuins = 192
    case ordelleSCaves = 193
    case outerHorutotoRuins = 194
    case theEldiemeNecropolis = 195
    case gusgenMines = 196
    case crawlersNest = 197
    case mazeOfShakhrami = 198
    case residentialArea2 = 199
    case garlaigeCitadel = 200
    case cloisterOfGales = 201
    case cloisterOfStorms = 202
    case cloisterOfFrost = 203
    case feiYin = 204
    case ifritSCauldron = 205
    case quBiaArena = 206
    case cloisterOfFlames = 207
    case quicksandCaves = 208
    case cloisterOfTremors = 209
    case gMHome = 210
    case cloisterOfTides = 211
    case gustavTunnel = 212
    case labyrinthOfOnzozo = 213
    case residentialArea3 = 214
    case abysseaAttohwa = 215
    case abysseaMisareaux = 216
    case abysseaVunkerl = 217
    case abysseaAltepa = 218
    case residentialArea4 = 219
    case shipBoundForSelbina = 220
    case shipBoundForMhaura = 221
    case provenance = 222
    case sanDOriaJeunoAirship = 223
    case bastokJeunoAirship = 224
    case windurstJeunoAirship = 225
    case kazhamJeunoAirship = 226
    case shipBoundForSelbina2 = 227
    case shipBoundForMhaura2 = 228
    case none2 = 229
    case southernSanDOria = 230
    case northernSanDOria = 231
    case portSanDOria = 232
    case chateauDOraguille = 233
    case bastokMines = 234
    case bastokMarkets = 235
    case portBastok = 236
    case metalworks = 237
    case windurstWaters = 238
    case windurstWalls = 239
    case portWindurst = 240
    case windurstWoods = 241
    case heavensTower = 242
    case ruLudeGardens = 243
    case upperJeuno = 244
    case lowerJeuno = 245
    case portJeuno = 246
    case rabao = 247
    case selbina = 248
    case mhaura = 249
    case kazham = 250
    case hallOfTheGods = 251
    case norg = 252
    case abysseaUleguerand = 253
    case abysseaGrauberg = 254
    case abysseaEmpyrealParadox = 255
    case westernAdoulin = 256
    case easternAdoulin = 257
    case ralaWaterways = 258
    case ralaWaterwaysU = 259
    case yahseHuntingGrounds = 260
    case ceizakBattlegrounds = 261
    case foretDeHennetiel = 262
    case yorciaWeald = 263
    case yorciaWealdU = 264
    case morimarBasaltFields = 265
    case marjamiRavine = 266
    case kamihrDrifts = 267
    case sihGates = 268
    case mohGates = 269
    case cirdasCaverns = 270
    case cirdasCavernsU = 271
    case dhoGates = 272
    case wohGates = 273
    case outerRaKaznar = 274
    case outerRaKaznarU = 275
    case raKaznarInnerCourt = 276
    case raKaznarTurris = 277
    case none1 = 278
    case walkOfEchoesP2 = 279
    case mogGarden = 280
    case leafallia = 281
    case mountKamihr = 282
    case celenniaMemorialLibrary = 284
    case feretory = 285
    case eschaZiTah = 288
    case eschaRuAun = 289
    case desuetiaEmpyrealParadox = 290
    case reisenjima = 291

    public var metadata: ZoneSceneMetadata {
        switch self {
        case .unknown: return Unknown()
        case .phanauetChannel: return PhanauetChannel()
        case .carpentersLanding: return CarpentersLanding()
        case .manaclipper: return Manaclipper()
        case .bibikiBay: return BibikiBay()
        case .uleguerandRange: return UleguerandRange()
        case .bearclawPinnacle: return BearclawPinnacle()
        case .attohwaChasm: return AttohwaChasm()
        case .boneyardGully: return BoneyardGully()
        case .psoXja: return PsoXja()
        case .theShroudedMaw: return TheShroudedMaw()
        case .oldtonMovalpolos: return OldtonMovalpolos()
        case .newtonMovalpolos: return NewtonMovalpolos()
        case .mineShaft2716: return MineShaft2716()
        case .hallOfTransference: return HallOfTransference()
        case .abysseaKonschtat: return AbysseaKonschtat()
        case .promyvionHolla: return PromyvionHolla()
        case .spireOfHolla: return SpireOfHolla()
        case .promyvionDem: return PromyvionDem()
        case .spireOfDem: return SpireOfDem()
        case .promyvionMea: return PromyvionMea()
        case .spireOfMea: return SpireOfMea()
        case .promyvionVahzl: return PromyvionVahzl()
        case .spireOfVahzl: return SpireOfVahzl()
        case .lufaiseMeadows: return LufaiseMeadows()
        case .misareauxCoast: return MisareauxCoast()
        case .tavnazianSafehold: return TavnazianSafehold()
        case .phomiunaAqueducts: return PhomiunaAqueducts()
        case .sacrarium: return Sacrarium()
        case .riverneSiteB01: return RiverneSiteB01()
        case .riverneSiteA01: return RiverneSiteA01()
        case .monarchLinn: return MonarchLinn()
        case .sealionSDen: return SealionSDen()
        case .alTaieu: return AlTaieu()
        case .grandPalaceOfHuXzoi: return GrandPalaceOfHuXzoi()
        case .theGardenOfRuHmet: return TheGardenOfRuHmet()
        case .empyrealParadox: return EmpyrealParadox()
        case .temenos: return Temenos()
        case .apollyon: return Apollyon()
        case .dynamisValkurm: return DynamisValkurm()
        case .dynamisBuburimu: return DynamisBuburimu()
        case .dynamisQufim: return DynamisQufim()
        case .dynamisTavnazia: return DynamisTavnazia()
        case .dioramaAbdhaljsGhelsba: return DioramaAbdhaljsGhelsba()
        case .abdhaljsIslePurgonorgo: return AbdhaljsIslePurgonorgo()
        case .abysseaTahrongi: return AbysseaTahrongi()
        case .openSeaRouteToAlZahbi: return OpenSeaRouteToAlZahbi()
        case .openSeaRouteToMhaura: return OpenSeaRouteToMhaura()
        case .alZahbi: return AlZahbi()
        case .none: return None()
        case .ahtUrhganWhitegate: return AhtUrhganWhitegate()
        case .wajaomWoodlands: return WajaomWoodlands()
        case .bhaflauThickets: return BhaflauThickets()
        case .nashmau: return Nashmau()
        case .arrapagoReef: return ArrapagoReef()
        case .ilrusiAtoll: return IlrusiAtoll()
        case .periqia: return Periqia()
        case .talaccaCove: return TalaccaCove()
        case .silverSeaRouteToNashmau: return SilverSeaRouteToNashmau()
        case .silverSeaRouteToAlZahbi: return SilverSeaRouteToAlZahbi()
        case .theAshuTalif: return TheAshuTalif()
        case .mountZhayolm: return MountZhayolm()
        case .halvung: return Halvung()
        case .lebrosCavern: return LebrosCavern()
        case .navukgoExecutionChamber: return NavukgoExecutionChamber()
        case .mamook: return Mamook()
        case .mamoolJaTrainingGrounds: return MamoolJaTrainingGrounds()
        case .jadeSepulcher: return JadeSepulcher()
        case .aydeewaSubterrane: return AydeewaSubterrane()
        case .leujaoamSanctum: return LeujaoamSanctum()
        case .chocoboCircuit: return ChocoboCircuit()
        case .theColosseum: return TheColosseum()
        case .alzadaalUnderseaRuins: return AlzadaalUnderseaRuins()
        case .zhayolmRemnants: return ZhayolmRemnants()
        case .arrapagoRemnants: return ArrapagoRemnants()
        case .bhaflauRemnants: return BhaflauRemnants()
        case .silverSeaRemnants: return SilverSeaRemnants()
        case .nyzulIsle: return NyzulIsle()
        case .hazhalmTestingGrounds: return HazhalmTestingGrounds()
        case .caedarvaMire: return CaedarvaMire()
        case .southernSanDOriaS: return SouthernSanDOriaS()
        case .eastRonfaureS: return EastRonfaureS()
        case .jugnerForestS: return JugnerForestS()
        case .vunkerlInletS: return VunkerlInletS()
        case .batalliaDownsS: return BatalliaDownsS()
        case .laVauleS: return LaVauleS()
        case .everbloomHollow: return EverbloomHollow()
        case .bastokMarketsS: return BastokMarketsS()
        case .northGustabergS: return NorthGustabergS()
        case .graubergS: return GraubergS()
        case .pashhowMarshlandsS: return PashhowMarshlandsS()
        case .rolanberryFieldsS: return RolanberryFieldsS()
        case .beadeauxS: return BeadeauxS()
        case .ruhotzSilvermines: return RuhotzSilvermines()
        case .windurstWatersS: return WindurstWatersS()
        case .westSarutabarutaS: return WestSarutabarutaS()
        case .fortKarugoNarugoS: return FortKarugoNarugoS()
        case .meriphataudMountainsS: return MeriphataudMountainsS()
        case .sauromugueChampaignS: return SauromugueChampaignS()
        case .castleOztrojaS: return CastleOztrojaS()
        case .westRonfaure: return WestRonfaure()
        case .eastRonfaure: return EastRonfaure()
        case .laTheinePlateau: return LaTheinePlateau()
        case .valkurmDunes: return ValkurmDunes()
        case .jugnerForest: return JugnerForest()
        case .batalliaDowns: return BatalliaDowns()
        case .northGustaberg: return NorthGustaberg()
        case .southGustaberg: return SouthGustaberg()
        case .konschtatHighlands: return KonschtatHighlands()
        case .pashhowMarshlands: return PashhowMarshlands()
        case .rolanberryFields: return RolanberryFields()
        case .beaucedineGlacier: return BeaucedineGlacier()
        case .xarcabard: return Xarcabard()
        case .capeTeriggan: return CapeTeriggan()
        case .easternAltepaDesert: return EasternAltepaDesert()
        case .westSarutabaruta: return WestSarutabaruta()
        case .eastSarutabaruta: return EastSarutabaruta()
        case .tahrongiCanyon: return TahrongiCanyon()
        case .buburimuPeninsula: return BuburimuPeninsula()
        case .meriphataudMountains: return MeriphataudMountains()
        case .sauromugueChampaign: return SauromugueChampaign()
        case .theSanctuaryOfZiTah: return TheSanctuaryOfZiTah()
        case .roMaeve: return RoMaeve()
        case .yuhtungaJungle: return YuhtungaJungle()
        case .yhoatorJungle: return YhoatorJungle()
        case .westernAltepaDesert: return WesternAltepaDesert()
        case .qufimIsland: return QufimIsland()
        case .behemothSDominion: return BehemothSDominion()
        case .valleyOfSorrows: return ValleyOfSorrows()
        case .ghoyuSReverie: return GhoyuSReverie()
        case .ruAunGardens: return RuAunGardens()
        case .mordionGaol: return MordionGaol()
        case .abysseaLaTheine: return AbysseaLaTheine()
        case .lobby: return Lobby()
        case .dynamisBeaucedine: return DynamisBeaucedine()
        case .dynamisXarcabard: return DynamisXarcabard()
        case .beaucedineGlacierS: return BeaucedineGlacierS()
        case .xarcabardS: return XarcabardS()
        case .castleZvahlBaileysS: return CastleZvahlBaileysS()
        case .horlaisPeak: return HorlaisPeak()
        case .ghelsbaOutpost: return GhelsbaOutpost()
        case .fortGhelsba: return FortGhelsba()
        case .yughottGrotto: return YughottGrotto()
        case .palboroughMines: return PalboroughMines()
        case .waughroonShrine: return WaughroonShrine()
        case .giddeus: return Giddeus()
        case .balgaSDais: return BalgaSDais()
        case .beadeaux: return Beadeaux()
        case .qulunDome: return QulunDome()
        case .davoi: return Davoi()
        case .monasticCavern: return MonasticCavern()
        case .castleOztroja: return CastleOztroja()
        case .altarRoom: return AltarRoom()
        case .theBoyahdaTree: return TheBoyahdaTree()
        case .dragonSAery: return DragonSAery()
        case .castleZvahlKeepS: return CastleZvahlKeepS()
        case .throneRoomS: return ThroneRoomS()
        case .middleDelkfuttSTower: return MiddleDelkfuttSTower()
        case .upperDelkfuttSTower: return UpperDelkfuttSTower()
        case .templeOfUggalepih: return TempleOfUggalepih()
        case .denOfRancor: return DenOfRancor()
        case .castleZvahlBaileys: return CastleZvahlBaileys()
        case .castleZvahlKeep: return CastleZvahlKeep()
        case .sacrificialChamber: return SacrificialChamber()
        case .garlaigeCitadelS: return GarlaigeCitadelS()
        case .throneRoom: return ThroneRoom()
        case .ranguemontPass: return RanguemontPass()
        case .bostaunieuxOubliette: return BostaunieuxOubliette()
        case .chamberOfOracles: return ChamberOfOracles()
        case .toraimaraiCanal: return ToraimaraiCanal()
        case .fullMoonFountain: return FullMoonFountain()
        case .crawlersNestS: return CrawlersNestS()
        case .zeruhnMines: return ZeruhnMines()
        case .korrolokaTunnel: return KorrolokaTunnel()
        case .kuftalTunnel: return KuftalTunnel()
        case .theEldiemeNecropolisS: return TheEldiemeNecropolisS()
        case .seaSerpentGrotto: return SeaSerpentGrotto()
        case .veLugannonPalace: return VeLugannonPalace()
        case .theShrineOfRuAvitau: return TheShrineOfRuAvitau()
        case .stellarFulcrum: return StellarFulcrum()
        case .laLoffAmphitheater: return LaLoffAmphitheater()
        case .theCelestialNexus: return TheCelestialNexus()
        case .walkOfEchoes: return WalkOfEchoes()
        case .maquetteAbdhaljsLegionA: return MaquetteAbdhaljsLegionA()
        case .lowerDelkfuttSTower: return LowerDelkfuttSTower()
        case .dynamisSanDOria: return DynamisSanDOria()
        case .dynamisBastok: return DynamisBastok()
        case .dynamisWindurst: return DynamisWindurst()
        case .dynamisJeuno: return DynamisJeuno()
        case .residentialArea1: return ResidentialArea1()
        case .kingRanperreSTomb: return KingRanperreSTomb()
        case .dangrufWadi: return DangrufWadi()
        case .innerHorutotoRuins: return InnerHorutotoRuins()
        case .ordelleSCaves: return OrdelleSCaves()
        case .outerHorutotoRuins: return OuterHorutotoRuins()
        case .theEldiemeNecropolis: return TheEldiemeNecropolis()
        case .gusgenMines: return GusgenMines()
        case .crawlersNest: return CrawlersNest()
        case .mazeOfShakhrami: return MazeOfShakhrami()
        case .residentialArea2: return ResidentialArea2()
        case .garlaigeCitadel: return GarlaigeCitadel()
        case .cloisterOfGales: return CloisterOfGales()
        case .cloisterOfStorms: return CloisterOfStorms()
        case .cloisterOfFrost: return CloisterOfFrost()
        case .feiYin: return FeiYin()
        case .ifritSCauldron: return IfritSCauldron()
        case .quBiaArena: return QuBiaArena()
        case .cloisterOfFlames: return CloisterOfFlames()
        case .quicksandCaves: return QuicksandCaves()
        case .cloisterOfTremors: return CloisterOfTremors()
        case .gMHome: return GMHome()
        case .cloisterOfTides: return CloisterOfTides()
        case .gustavTunnel: return GustavTunnel()
        case .labyrinthOfOnzozo: return LabyrinthOfOnzozo()
        case .residentialArea3: return ResidentialArea3()
        case .abysseaAttohwa: return AbysseaAttohwa()
        case .abysseaMisareaux: return AbysseaMisareaux()
        case .abysseaVunkerl: return AbysseaVunkerl()
        case .abysseaAltepa: return AbysseaAltepa()
        case .residentialArea4: return ResidentialArea4()
        case .shipBoundForSelbina: return ShipBoundForSelbina()
        case .shipBoundForMhaura: return ShipBoundForMhaura()
        case .provenance: return Provenance()
        case .sanDOriaJeunoAirship: return SanDOriaJeunoAirship()
        case .bastokJeunoAirship: return BastokJeunoAirship()
        case .windurstJeunoAirship: return WindurstJeunoAirship()
        case .kazhamJeunoAirship: return KazhamJeunoAirship()
        case .shipBoundForSelbina2: return ShipBoundForSelbina()
        case .shipBoundForMhaura2: return ShipBoundForMhaura()
        case .none2: return None()
        case .southernSanDOria: return SouthernSanDOria()
        case .northernSanDOria: return NorthernSanDOria()
        case .portSanDOria: return PortSanDOria()
        case .chateauDOraguille: return ChateauDOraguille()
        case .bastokMines: return BastokMines()
        case .bastokMarkets: return BastokMarkets()
        case .portBastok: return PortBastok()
        case .metalworks: return Metalworks()
        case .windurstWaters: return WindurstWaters()
        case .windurstWalls: return WindurstWalls()
        case .portWindurst: return PortWindurst()
        case .windurstWoods: return WindurstWoods()
        case .heavensTower: return HeavensTower()
        case .ruLudeGardens: return RuLudeGardens()
        case .upperJeuno: return UpperJeuno()
        case .lowerJeuno: return LowerJeuno()
        case .portJeuno: return PortJeuno()
        case .rabao: return Rabao()
        case .selbina: return Selbina()
        case .mhaura: return Mhaura()
        case .kazham: return Kazham()
        case .hallOfTheGods: return HallOfTheGods()
        case .norg: return Norg()
        case .abysseaUleguerand: return AbysseaUleguerand()
        case .abysseaGrauberg: return AbysseaGrauberg()
        case .abysseaEmpyrealParadox: return AbysseaEmpyrealParadox()
        case .westernAdoulin: return WesternAdoulin()
        case .easternAdoulin: return EasternAdoulin()
        case .ralaWaterways: return RalaWaterways()
        case .ralaWaterwaysU: return RalaWaterwaysU()
        case .yahseHuntingGrounds: return YahseHuntingGrounds()
        case .ceizakBattlegrounds: return CeizakBattlegrounds()
        case .foretDeHennetiel: return ForetDeHennetiel()
        case .yorciaWeald: return YorciaWeald()
        case .yorciaWealdU: return YorciaWealdU()
        case .morimarBasaltFields: return MorimarBasaltFields()
        case .marjamiRavine: return MarjamiRavine()
        case .kamihrDrifts: return KamihrDrifts()
        case .sihGates: return SihGates()
        case .mohGates: return MohGates()
        case .cirdasCaverns: return CirdasCaverns()
        case .cirdasCavernsU: return CirdasCavernsU()
        case .dhoGates: return DhoGates()
        case .wohGates: return WohGates()
        case .outerRaKaznar: return OuterRaKaznar()
        case .outerRaKaznarU: return OuterRaKaznarU()
        case .raKaznarInnerCourt: return RaKaznarInnerCourt()
        case .raKaznarTurris: return RaKaznarTurris()
        case .none1: return None1()
        case .walkOfEchoesP2: return WalkOfEchoesP2()
        case .mogGarden: return MogGarden()
        case .leafallia: return Leafallia()
        case .mountKamihr: return MountKamihr()
        case .celenniaMemorialLibrary: return CelenniaMemorialLibrary()
        case .feretory: return Feretory()
        case .eschaZiTah: return EschaZiTah()
        case .eschaRuAun: return EschaRuAun()
        case .desuetiaEmpyrealParadox: return DesuetiaEmpyrealParadox()
        case .reisenjima: return Reisenjima()

        }
    }
    
    public var spawnPoint: SIMD3<Float>? {
        metadata.lines.first?.position
    }
    
    public var nodeName: String {
        .init(rawValue)
    }
}
