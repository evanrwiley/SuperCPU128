/* list c64 font */

#include <stdio.h>

int
main (int argc, char** argv)
{
  int c, i;
  int count = 0, ccount = 0, set = 1;

  while ((c = getchar ()) != EOF) {
    printf ("%x-%02x: ", set, ccount);

    for (i = 7; i >= 0; i--)
      putc (c & (1 << i) ? '*' : ' ', stdout);

    putchar ('\n');

    if (++count == 8) {
      ccount++;
      count = 0;
      putchar ('\n');
    }
    if (ccount == 256) {
      set++;
      ccount = 0;
    }
  }
}
