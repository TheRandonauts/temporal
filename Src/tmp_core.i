

void BookHitter::FindMinMax() {
	GenApproach& S = *App;
	if (DuringStability and S.Stats.FailedCount) return;

	int Su = S.IsSudo() * 2;
	auto& Min = *MinMaxes[0 + Su];
	auto& Max = *MinMaxes[1 + Su];
	
	Min.UseCount++;
	Max.UseCount++;
	
	for_(5) {
		Max[i] = max(S[i], Max[i]);
		Min[i] = min(S[i], Min[i]);
	}
}


float BookHitter::FinalExtractAndDetect (int Mod) {
	if (IsRetro()) {
		ExtractRetro(self);
	 } else {
		ExtractRandomness(self, 0, {});
		App->Stats.Length /= 32;             // for style. less is more.
		TryLogApproach();
		
		ExtractRandomness(self, Mod, App->FinalFlags());
		TryLogApproach("p");
	}
	
	return DetectRandomness();
}


static int FinishApproach(BookHitter& B, float Time) {
	auto& App = *B.App;
	App.Fails += App.Stats.FailedCount;
	B.Stats.ProcessTime += Time;
	B.Stats.WorstScore = max(B.Stats.WorstScore, App.Stats.Worst);
	return App.Stats.Length;
}


int BookHitter::UseApproach () {
	auto  t_Start = Now();
	int   BestMod = 0;
	float BestScore = 1000000.0;
	
	if (!IsRetro()) for (auto Mod : ModList) {
		ExtractRandomness(self, Mod, App->DetectFlags());
		float Score = DetectRandomness();
		if (Score < BestScore) {
			BestMod = Mod;
			BestScore = Score;
		}
	}
	
	FinalExtractAndDetect(BestMod);
	FindMinMax();
	return FinishApproach(self, ChronoLength(t_Start));
}


NamedGen* BookHitter::NextApproachOK(GenApproach& app, NamedGen* LastGen) {
	this->App = &app;
	if ( app.Gen != LastGen and LogOrDebug() )
		printf( "\n:: %s gen :: \n", app.Gen->Name );
	LastGen = app.Gen;
	
	float T = TemporalGeneration(self, app);
	require(!Stats.Err);
	if (LogOrDebug())
		printf( "	:: %03i    \t(took %.3fs) ::\n", app.Reps, T );
	return LastGen;
}


static IntVec& RepListFor(BookHitter& B, NamedGen* G) {
	if (G->GenType == kChaotic) {
		B.ChaoticRepList = {};
		for_(15) B.ChaoticRepList.push_back(i+1);
		return B.ChaoticRepList;
	}
	
	return B.RepList;
}


static void CreateApproachSub(BookHitter& B, NamedGen* G) {
	auto List = RepListFor(B, G);
	for (auto R : List) {
		auto App = GenApproach::neww(&B);
		bool Sudo = App->SetGenReps(G, R);
		B.ApproachList.push_back(App);
		if (Sudo) return;
	}
}


void BookHitter::CreateApproaches() {
	RescoreIndex = 0;
	ApproachList = {};
	BasicApproaches = {};
	RetroApproaches = {};
	ChaoticApproaches = {};

	for (auto G = &TmpGenList[0];  G;  G = NextGenerator(G))
		CreateApproachSub(self, G);

	App = 0;
	ResetMinMaxes();
}


static void XorCopy(u8* Src, u8* Dest, int N) {
	u8* Write = Dest;
	while (N-- > 0)
		*Write++ = *Src++ ^ *Dest++;
}


bool BookHitter::CollectPieceOfRandom (RandomBuildup& B) {
	B.Chan = ViewChannel();
	require(!Stats.Err);
	u32 Least = -1; 

	while (B.KeepGoing()) {
		OnlyNeedSize(B.Remaining);
		TemporalGeneration(self, *B.Chan);
		require(!Stats.Err);
	
		u32 N = min(UseApproach(), B.Remaining);
		Least = min(Least, N);
		if (IsRetro())
			XorRetro(Extracted(),  B.Data,  N);
		  else
			XorCopy (Extracted(),  B.Data,  N);
		B.AllWorst = max(B.AllWorst, B.Worst());
	}

	RequestLimit = 0; // cleanup.
	B.Data += Least;
	Stats.BytesOut += Least;
	B.Remaining -= Least;
	if (B.Remaining > 0) return true;

	return false;
}


Ooof void StopStrip(BookHitter&B) {
	// I can't debug if the compiler strips out these functions!
	if (B.Samples.size() == 1) { // should never happen
		PrintHisto(B);
		PrintProbabilities();
		DebugSamples(B);
	}
}



bh_stats* BookHitter::Hit (u8* Data, int DataLength) {
	if (!Data) return 0; // wat?

	CreateDirs();

	memset(Data, 0, DataLength);
	RandomBuildup B = {Data, DataLength, IsRetro()};
	Stats = {};

	while (CollectPieceOfRandom(B))
		B.Loops = 0;

	if (Conf.AutoRetest)
		Retest();
		
	return &Stats;
}


Ooof void ReportStuff (bh_stats* Result) {
	float M = ((float)(Result->SamplesGenerated))/1000000.0;
	float K = ((float)(Result->SamplesGenerated))/1000.0;
	
	if (M > 0.1)
		printf(":: %.2fM", M);
	  else
		printf(":: %.2fK", K);
	printf(" samples⇝%iKB ::\n", (Result->BytesOut/1024));
}
