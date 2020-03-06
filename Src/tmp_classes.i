



struct RandoStats {
	float		Entropy;
	float		ChiSq;
	float		Mean;
	float		Monte;
	float		Hist;
	float       Worst;
	int			Length;
	u32			BitsRandomised;
	u8			FailedCount;
	u8			FailedIndexes;
	u8			Type		: 4;
	u8			WorstIndex	: 4;
	
	void Unify(int i, float Low, float High, float Bad, float Value);
	float& operator[] (int i) {
		return (&Entropy)[i];
	}
};


struct Shrinkers {
	u32 PreXOR	: 6;
	u32 Vonn	: 1;
	u32 Histo	: 1;
	u32 PostXOR	: 6;
	u32 Log		: 1;
};


struct GenApproach {
	BookHitter*	Owner;
	NamedGen*	Gen;
	RandoStats  Stats;
	float		Mean;
	float		GenTime;
	u32			Highest;
	u16			Fails;
	u16			Reps;
	u16			UseCount;
	
	
	static Shrinkers ShrinkFlags_(GenApproach* App) {
		Shrinkers Result = {16, 1, 1};
		if (App and App->IsChaotic())
			Result.PreXOR = 4;
		return Result;
	}
	
	Shrinkers FinalFlags() {
		auto Result = ShrinkFlags_(this);
		Result.Log = true;
		return Result;
	}
	
	Shrinkers DetectFlags() {
		auto Result = ShrinkFlags_(this);
		Result.Histo = 0;
		return Result;
	}
	
	static int Shrink (GenApproach* App) {
		auto Flags = ShrinkFlags_(App);		
		int n = 1;
		if (Flags.Vonn)		n *= 5;  // 4x on average, but lets say 5 to be safe.
		if (Flags.PreXOR)	n *= Flags.PreXOR;
		if (Flags.PostXOR)	n *= Flags.PostXOR;
		return n;
	}

	bool SetGenReps(NamedGen* G, int R) {
		Gen  = G;
		Reps = (R*10 + 9) / G->Slowness;
		return IsSudo();
	}
	void EndExtract() {
		Fails += Stats.FailedCount;
	}
	float& operator[] (int i) {
		return (&Stats.Entropy)[i];
	}
	bool IsSudo() {
		return Gen and (Gen->GenType == kSudo);
	}
	bool IsChaotic() {
		return Gen and (Gen->GenType == kChaotic);
	}
	u64 StablePRndSeed(u64 i = 0) { // Stable-pRnd that changes between runs.
		return (UseCount + 1 + i) * (100 + Reps);
	}
	u32 Cap(u32 Mod) {
		if (IsSudo()) return -1;
		u32 H = Highest;
		return H - (H % Mod);
	}

	void DebugName();
	string NameSub();
	string Name() {
		return Name_(this);
	}
	string FileName(string s="") {
		return FileName_(this, s);
	}
	static string Name_(GenApproach* App) {
		if (App and App->Stats.Type)   return MaxNames[App->Stats.Type];
		if (!App or !App->Gen) return "unknown_";
		return App->NameSub();
	}
	static string FileName_(string Name, string s="") {
		return "time_imgs/" + Name + s + ".png";
	}
	static string FileName_(GenApproach* App, string s="") {
		return FileName_(Name_(App), s);
	}
	static std::shared_ptr<GenApproach> neww(BookHitter* Owner) {
		auto M = New(GenApproach);
		*M = {Owner};
		return M;
	}
};


u64 Seed(GenApproach* A, u64 x) {
	if (!A)
		return (x*10000 + 123)^90128381273176487ull;
	return A->StablePRndSeed(x);
}


struct RandTest {
	constexpr static const int MONTEN = 6.0;
	constexpr static const double BIGX = 20.0;

	int			ccount[256];			/* Bins to count occurrences of values */
	int			totalc;					/* Total bytes counted */
	int			AsBits;					/* Treat input as a bitstream */
	int			mp;
	int			intsccfirst;
	int			inmont;
	int			mcount;
	u32			monte[MONTEN];

//  Funcs
	void		add_byte (int oc);
	void		end(GenApproach& Result);
};


struct RandomBuildup {
	u8*				Data;
	int				Remaining;
	bool			IsRetro;
	float			AllWorst;
	GenApproach*    Chan;
	int				Loops;
	
	float Worst() {
		return max(Chan->Stats.Worst, 0.0f);
	}
	
	bool KeepGoing() {
		Loops++;
		if (!Chan->Stats.FailedCount) {
			if (Chan->IsChaotic() or IsRetro)
				return Loops <= 1;
			return Loops <= 3; // be safe...
		}
		if (IsRetro)
			return Loops <= 3;
		return Loops <= 8; 
	}
};


struct BookHitter {
	GenApproach*	App;
	pthread_t		GeneratorThread;
	SampleVec		Samples;
	IntVec			SampleHisto;
	ByteArray		Buff;
	ByteArray		BSL;
	IntVec			RepList;
	IntVec			ChaoticRepList;
	ApproachVec		ApproachList;
	ApproachVec		RetroApproaches;
	ApproachVec		ChaoticApproaches;
	ApproachVec		BasicApproaches;
	ApproachVec		MinMaxes;
	bh_stats		Stats;
	bh_conf			Conf;
	short			DebugLoopCount;
	u32				RequestLimit;
	u8				RescoreFreq;
	u8				RescoreIndex;
	u8				DuringStability;
	bool			RescoreSelf;
	bool			CreatedDirs;

// // Funcs
	bh_stats*		Hit (u8* Data, int DataLength);
	void			Retest();
	void 			SetCrashHandler();
	float			DetectRandomness ();
	void			CreateDirs();
	void			CreateHTMLRandom(ApproachVec& V, string Name, string Title);
	void			DebugProcessFile(string Name);
	void			FindMinMax();
	ref(HTML_Random) HTML(string s, string n);	
	void			CreateApproaches();
	int				UseApproach ();
	NamedGen*		NextApproachOK(GenApproach& App, NamedGen* LastGen);	
	bool			CollectPieceOfRandom (RandomBuildup& B);
	void			BestApproachCollector(ApproachVec& L);
	ApproachVec&	FindBestApproach(ApproachVec& L);
	float			FinalExtractAndDetect (int Mod);
	void			TryLogApproach(string name);


	string FileName(string s = "") {
		return GenApproach::FileName_(App, s);
	}
	
	
	void SetChannel(int i) {
		unsigned char s = i;
		if (i!=s) {
			printf("Can't set channel %i, out of range (-128 to 127)\n", i);
		} else {
			Conf.Channel = s;
		}
	}
	
	bool NoImgs() {
		return (DuringStability == 2);
	}

	bool LogOrDebug() {
		if (Conf.Log == 255) return false;
		return DEBUG_AS_NUM or Conf.Log;
	}

	bool IsRetro() {
		return Conf.Channel > 0;
	}

	bool IsChaotic() {
		return Conf.Channel == 0;
	}
	
	bool ChaosTesting() {
		return IsChaotic() and DuringStability;
	}
	
	void OnlyNeedSize(int N) {
		N = max(N, 0);
		if (IsRetro()) {
			RequestLimit = N;
		} else {
			int Shrink = GenApproach::Shrink(App);
			int SafeExtra = 256;
			int BitsToBytes = 8;
			RequestLimit = (SafeExtra + Shrink * N)*BitsToBytes;
		}
	} 

	int UserChannelIndex() {
		int i = Conf.Channel;
		if (i < 0)
			i = -i;
		if (i) i--;
		return i;
	}
	
	GenApproach* ViewChannel() {
		auto& L = ApproachesForChannel();
		int i = UserChannelIndex() % L.size();
		App = L[i].get();
		return App;
	}
	
	ApproachVec& ApproachesForChannel() {
		if (IsChaotic())
			return FindBestApproach(ChaoticApproaches);
		  else if (IsRetro())
			return FindBestApproach(RetroApproaches);
		  else
			return FindBestApproach(BasicApproaches);
	}
	
	void ResetMinMaxes() {
		MinMaxes = {};
		float Signs[] = {1.0, -1.0};
		for_(4)
			AddM(copysign(100000000, Signs[i%2]), i + 1);
	}

	uSample* Out() {
		return &(Samples[0]);
	}
	u8* BitSections() {
		return &BSL[0];
	}
	u8* Extracted() {
		return &(Buff[0]);
	}
	int Space() {
		int N = (int)Samples.size();
		
		if (ChaosTesting())
			return N / 16;

		if (RequestLimit > 0 and RequestLimit < N)
			return RequestLimit;
		
		return N;
	}
	int GenSpace() {
		if (IsRetro()) // half extra, for temporal cohesion...
			return (RetroCount*8)+(RetroCount/2);
		return Space();
	}
	void AddM (float Default, int Type) {
		auto M = GenApproach::neww(this);
		for_(5) (*M)[i] = Default;
		M->Stats.Type = Type;
		MinMaxes.push_back(M);
	}
	void Allocate(int N) {
		Samples.resize(N);
		Buff.resize(Samples.size()/8);
		BSL.resize(Samples.size()+1);
	}
	void CreateReps(int* Reps) {
		if (!Reps) {
			RepList = {3, 5,  9,  17,  25, 31};
		#if DEBUG
			RepList = {3, 5,  9,  17,  25};
		#endif
		} else {
			RepList = {};
			while (*Reps)
				RepList.push_back(*Reps++);
		}
		CreateApproaches();
	}
};


void GenApproach::DebugName() {
	if (Owner->LogOrDebug()) {
		string s = Name();
		printf("%s ", s.c_str());
	}
}


string GenApproach::NameSub() {
	string name = string(Gen->Name);
	if (!IsSudo()) {
		name += to_string(Reps);
		if (Owner->DuringStability==1)
			name += "_"; // test
	}
	if (!Owner->NoImgs() and Owner->DebugLoopCount) {
		name += "_loop" + to_string(Owner->DebugLoopCount);
	}
	   
	return name;
}

