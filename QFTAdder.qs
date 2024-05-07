namespace QFTAdd {
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Unstable.Arithmetic;


    @EntryPoint()
    operation main(): Unit {
        let len = 4;
        use a = Qubit[len];
        use b = Qubit[len];

        // a = 5, b = 5
        X(a[0]);
        X(a[2]);
        X(b[0]);
        X(b[2]);
        

        let resultsa = MeasureEachZ(a);
        let resultsb = MeasureEachZ(b);
        let inta = ResultArrayAsInt(resultsa);
        let intb = ResultArrayAsInt(resultsb);

        Message($"a: {inta}, b: {intb}");


        
        Adder(a,b);

        let resultsa = MeasureEachZ(a);
        let resultsb = MeasureEachZ(b);
        let inta = ResultArrayAsInt(resultsa);
        let intb = ResultArrayAsInt(resultsb);

        Message($"a: {inta}, a + b: {intb}");


        use s = Qubit[len*2];
        // Multiply(inta, b);
        QFTMult(a, b, s);

        let resultss = MeasureEachZ(s);
        let ints = ResultArrayAsInt(resultss);

        Message($"a: {inta}, a(a + b): {ints}");

        ResetAll(a);
        ResetAll(b);
        ResetAll(s);
    }

    // Adder
    // 
    // Takes two input registers, adds them, and puts the result in b
    // Based off of draper adder
    // 
    // a: input register 1, should be same length as b
    // 
    // b: input/output register, should be same length as a
    //    
    // result: b register ends up with |a + b>
    operation Adder(a : Qubit[], b : Qubit[]) : Unit is Adj + Ctl {
        // reverse a
        SwapReverseRegister(a);
        // Apply QFT to second(output) register
        ApplyQFT(b);

        let n = Length(a);
        for i in 0 .. n - 1 {
            for j in 0 .. (n - 1) - i {
            Controlled R1Frac([a[i + j]], (2, j + 1, (b)[(n - 1) - i]));
            }
        }

        // Apply inverse QFT to the result qubits
        Adjoint ApplyQFT(b);
        SwapReverseRegister(a);
    }

    operation Multiply(a: Int, b: Qubit[]): Unit{
        let len = Length(b);
        use s = Qubit[len];

        for i in 0 .. a - 1{
            Adder(b, s);
        }
        
        ApplyToEachCA(SWAP, Zipped(b, s));

        ResetAll(s);
    }

    // a and b should be the same size, output should be double
    operation QFTMult(a: Qubit[], b: Qubit[], out: Qubit[]): Unit {
        let len = Length(a);

        // b should be big endian
        // SwapReverseRegister(b);

        let resultss = MeasureEachZ(out);
        let ints = ResultArrayAsInt(resultss);

        Message($"out: {ints}");

        ApplyQFT(out);

        for i in 1 .. len {
            for j in 1 .. len {
                for k in 1 .. 2*len {
                    let theta = ((2.0 * PI()) / (2.0 ^ IntAsDouble(i + j + k - 2 * len)));
                    Controlled R1([a[len - j], b[len - i]], (theta, out[k - 1]));
                }
            }
        }
        

        Adjoint ApplyQFT(out);
    }

    operation TwosComp(x: Qubit[]): Unit{
        let len = Length(x);
        mutable firstOneFound = false;
        // flips all qubits after first 1 read. 
        // little endian is assumed
        for i in 0 .. len - 1{
            if firstOneFound {
                X(x[i]);
            }
            else {
                if M(x[i]) == One {
                    set firstOneFound = true;
                }
            }
        }
    }

    operation ResultArrayAsTwos(x: Qubit[]): Int {
        let len = Length(x);
        mutable result = 0;

        for i in 0 .. len - 2 {
            if (M(x[i]) == One){
                set result += (2^i);
            }
        }

        if (M(x[len-1]) == One) {
            set result = result * -1;
        }
        return result;
    }
}


