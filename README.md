MFCALC
======

Improved version of mfcalc with gnu-flex and multivariable functions added.

### Clone
You can clone this repository with git

      git clone https://github.com/jcatumba/mfcalc.git

### Compile
In order to construct the binary file just type on your interpreter

      make

### Run
To run the program just type

      ./mfcalc.bin

Supported operations
--------------------

### Basic arithmetic operations

      [mfcalc]: 3 + 4
      [mfcalc]: 13 - 2
      [mfcalc]: 21 * 15
      [mfcalc]: 17 / 3
      [mfcalc]: 2^5

### Basic mathematical functions

      [mfcalc]: cos(0)
      [mfcalc]: ln(4)
      [mfcalc]: exp(3)
      [mfcalc]: sin(3.14159)
      [mfcalc]: max(15, 3*8)
      [mfcacl]: min(7/6, 4, ln(4))

### Variable definition

      [mfcalc]: pi = 3.14159
      [mfcalc]: cos(pi)

### Composition

      [mfcalc]: ln(sin(pi))

### Echoed strings

      [mfcalc]: "hello"
