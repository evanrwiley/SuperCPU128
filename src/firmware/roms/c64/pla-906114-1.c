/** Program to convert logic equations
 * of 16 inputs and 8 outputs
 * to a 64-kilobyte truth table.
 * @author Marko Mäkelä (msmakela@nic.funet.fi)
 * @date 2nd July 2002, updated 8th July 2003
 * The equations in this program have been translated from the
 * MACHXL design description supplied by Jens Schönfeld (jens@ami.ga),
 * and verified against the 64-kilobyte dumps supplied by Jens Schönfeld.
 *
 * Compilation:
 *	cc -o pla 906114-1.c
 * Example usage:
 *	./pla | diff - pla-dump.bin
 * or
 *	./pla > pla-dump.bin
 */

#include <stdio.h>

/** Extract an input bit
 * @param b	the bit to be extracted
 * @return	nonzero if the input bit b is set
 */
#define I(b) (!!((i) & (1 << b)))

/** @name The input signals.
 * This mapping corresponds to the 82S100 to 27512 adapter made by
 * Jens Schönfeld (jens@ami.ga).  Note also the permutation of outputs
 * in the main loop.
 */
/*@{*/
#define I0	I(1)
#define I1	I(2)
#define I2	I(3)
#define I3	I(4)
#define I4	I(5)
#define I5	I(6)
#define I6	I(7)
#define I7	I(12)
#define I8	I(14)
#define I9	I(13)
#define I10	I(8)
#define I11	I(9)
#define I12	I(11)
#define I13	I(15)
#define I14	I(10)
#define I15	I(0)
/*@}*/

/** @name The output signals. */
/*@{*/
/* CASRAM_ */
#define F0	(!(F5&&F7&&F6&&F3&&F1&&F2)||			\
		 I0||						\
		 (!I0 && I12 && !I13 && !I5 && I6)||		\
		 (!I0 && I12 && !I13 && !I6 && I7)||		\
		 (!I0 && I12 && !I13 && !I5 &&!I6&&!I7&&I8)||	\
		 (!I0 && I12 && !I13 && I5 && I6&&!I7&&!I8))
/* BASIC_ */
#define F1	!(I5&&!I6&&I7&&I1&&I2&&I13&&!I10&&I11)
/* KERNAL_ */
#define F2	!((I5&&I6&&I7&&I2&&I13&&!I10&&I11)||		\
		  (I5&&I6&&I7&&I2&&!I13&&!I12&&!I10&&I11))
/* CHAROM_ */
#define F3	!((I5&&I6&&!I7&&I8&&!I3&&!I2&&I1&&I13&&!I10&&I11)||	\
		  (I5&&I6&&!I7&&I8&&!I3&&I2&&I13&&!I10&&I11)||		\
		  (I5&&I6&&!I7&&I8&&!I3&&I2&&!I13&&!I12&&!I10&&I11)||	\
		  (I10&&I12&& I13&&I4&&!I14&&I15)||			\
		  (I10&&!I12&&I4&&!I14&&I15))
/* GR/W */
#define F4	!(!I0 && I5 && I6 &&!I7&&I8&&!I10&&!I11)
/* I_O_ */
#define F5	!((I5&&I6&&!I7&&I8&&I3&&I1&&!I2&&!I10&&!I11)||		\
		  (I5&&I6&&!I7&&I8&&I3&&I2&&!I10&&!I11)||		\
		  (I5&&I6&&!I7&&I8&&I12&&!I13&&!I10&&!I11)||		\
		  (I5&&I6&&!I7&&I8&&I3&&I1&&!I2&&!I10&&I11&&I9)||	\
		  (I5&&I6&&!I7&&I8&&I3&&I2&&!I10&&I11&&I9)||		\
		  (I5&&I6&&!I7&&I8&&I12&&!I13&&!I10&&I11&&I9))
/* ROML_ */
#define F6	!((I5&&!I6&&!I7&&!I10&&I11&&!I12&&I1&&I2)||	\
		  (I5&&!I6&&!I7&&!I10   &&I12&&!I13))
/* ROMH_ */
#define F7	!((I5&&!I6&&I7&&!I10&&I11&&I2&&!I12&&!I13)||	\
		  (I5&&I6&&I7&&!I10&&!I13&&I12)||		\
		  (I15&&I14&&I10&&!I13&&I12))
/*@}*/

/** The main program
 * @param argc	command line argument count
 * @param argv	command line argument vector
 * @return	zero on successful termination
 */
int
main (int argc, char** argv)
{
  /** The input combination, at least 16 bits */
  register unsigned int i = 0;
  do {
    /** The output combination, 8 bits */
    register unsigned char o = 0;
    /* The outputs are permuted so that they correspond to the adapter
     * made by Jens Schönfeld.
     */
    if (F0) o |= 1 << 6;
    if (F1) o |= 1 << 5;
    if (F2) o |= 1 << 4;
    if (F3) o |= 1 << 3;
    if (F4) o |= 1 << 2;
    if (F5) o |= 1 << 1;
    if (F6) o |= 1 << 0;
    if (F7) o |= 1 << 7;
    putchar (o);
  }
  while (++i & 0xffff);
  return 0;
}
