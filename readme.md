
# about

The idea is to generate random numbers, using the CPU's time() instruction, usually `rtdsc` on intel.

Time information is really important and interesting, because it is a physical sensor, like a camera-pixel or a microphone. We can try get randomness from this sensor. However, it's an **internal** physical sensor, which we hope we can do extra cool things with.

This is research to play around with! Don't expect anything more than that! Have fun experimenting or don't bother opening.

It should generate some randomness pictures in a `time_img` folder in your current directory. Quite interesting and fun pictures!

![Temporal Randomness](screenshot.png)

This project was inspired by the fatum project, a totally cool project about: Novelty, deeper mystery, and expanded exploration. Give it a look. http://randonauts.com



# single header   

Can be used as a single-header project, like the stb-nothings files can be, using `temporal_research.h` (`temporal_main.cpp` is not needed to generate randomness, and is just a test file.)
    


# compile

compile: `gcc -std=c++0x -lc++ -Os temporal_main.cpp -o temporal`
or use the Xcode project supplied



# Efforts made

* The design of the code is important. We need to "defeat optimisations". For example my time-generator doesn't just call `Time32`, it ALSO xor's the result and returns it, ensuring it isn't optimised away.
* Also, our time is 32-bit, 4GB time-deltas is plenty!
* We use warmups to help timings.
* We try various mod sizes to extract randomness. (like `temporal_rand() mod 17`)
* We use some defines to make code more consistant. `Time_`, `for_`, `Gen`
* Detects and rejects time-spikes caused by interupts, contention, etc.
    

# Please experiment:

Improve / replace any code in here... for example:

    Time_ (Reps) {
        y = y + 1000.5;
        x = x / 2.0;
        x = fmodf(x,2.0) - (x / 10000000.0);
        x = floor(x)     - (x * 5000000.0);
        x = fminf(x, MAXFLOAT);
        y = fmaxf(y,-MAXFLOAT);
        x += y;
    } TimeEnd

* Do we need so many instructions? Do we need all? Some? Who knows! I don't! haha.
* What about altering Reps? That affects things a lot! Are more reps good or less? Or certain numbers (primes?) of samples?
* Modern CPUs try to reduce time randomness. For us its undesirable! Perhaps rarer CPUs have more random timings? Could be interesting!
* It would be a cool idea to make the randomness generated be animated, perhaps using SDL2.


# to do:

* Try to auto-detect "the best settings"? Needs a randomness-test!
    * Current randomness test isn't good enough.
* Allow "Choices" by temporal-logic? multiple temporal inputs, even? Let the CPU "play itself"!
* What about "opposing forces"? Like two energy-balls squeezed together. Can I do something like that with the bands? Like add them up but one in reverse order?
* Same-input should be the standard... (like especially for floats)
    * I guess we should try to find good same-input.
* Detect frequencies in the patterns and draw as a bar graph? Need FFT I guess.
    * Can anyone make the bars move?
