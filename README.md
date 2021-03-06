# CHARIS (CHAnia Risc Instruction Set) Assembler

The **MIPS_CHARIS_assembler.sh** is a shell script, written to assemble MIPS instructions to object code. CHARIS is a processor, designed and implemented as project of the _"ACE312 - Computer Organization"_, summer semester course, Technical University of Crete. It is an implementation of a subset from the MIPS instruction set.


The bash code is provided with a test file - _"test.mipsasm"_. You can run it on linux shell with:
``` 
./MIPS_CHARIS_assembler.sh test.mipsasm
```
Both assembly and the corresponding object code, are printed colorcoded. The assembly code is printed in file descriptor 2. You can print only the object code with:

``` 
./MIPS_CHARIS_assembler.sh test.mipsasm 2>/dev/null
```
You can also, print both and save object code to a file:

``` 
./MIPS_CHARIS_assembler.sh test.mipsasm  | tee tmp; cat tmp | sed 's/\x1b\[[0-9;]*m//g' > obj.txt
```

----------------------------------------------------------------------------------------------------------------------------------------------------------
Έφτιαξα αυτό το προγραμματάκι σε bash προς διευκόλυνσή μου, στις περιπτώσεις που ήθελα να παράγω πηγαίο δυαδικό κώδικα για τον CHARIS.
Τρέχει με bash. Παίρνει ένα μόνο όρισμα, το αρχείο σε εντολές assembly (όπως φαίνεται στο αρχείο "test.mipsasbl") και εξάγει το 32bit instruction για τη μνήμη.

Είναι κακογραμένο καθώς, αφιέρωσα ένα απόγευμα για να το φτιάξω, αλλά παρόλα αυτά μπορεί να παραμετροποιηθεί σε κάποια σημεία όπως θα δείτε.
Το έλεγξα με τα δυαδικά προγράμματα που έφτιαξα με το χέρι και είδα ότι ήταν σωστά τ'αποτελέσματα.
Ελπίζω να φανεί χρήσιμο στους φοιτητές μελλοντικά, αν δείτε ότι απαντά στα ποιοτικά πρότυπα του επεξεργαστή του μαθήματος.
