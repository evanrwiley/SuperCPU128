Mark Knibbs posted the following information on the cbm-hackers mailing list
on the 31st of December 2000.  William Levak pointed out:

> I see only one difference between this list and the documentation I have.

> Basic 3.0 ROM 901465-24 is listed in my documentation as 901447-24.

On 22-Dec-00, William Levak wrote:
>> A while ago I received some old documentation that Commodore USA sent to
>> dealers and repair centres. A couple of pages of this listed ROM part
>> numbers for various PET-era computers and disk drives. If it might be of
>> help I can type up those pages and post them to the list.
> 
> What kind of documentation is that?   Documentation on the early equipment
> is very scarce.

Some TechTopics material, from memory circa 1982-1987, plus various stuff
including a technical support bulletin from January 1982.

Eventually I hope to be able to scan the documents. (If anyone can help with
getting a Fujitsu M3191F2 Image Scanner to be recognised when connected to an
Adaptec SCSI controller in a PC, please let me know.)

In the mean time, I have typed up the tech bulletin contents page and the ROM
Genealogy article. Hopefully all typos below are also present in the original
document.




                  COMMODORE TECHNICAL SUPPORT BULLETIN



                                Contents



1        Introduction

Computers and Languages

2        BASIC 4.0 Memory Map
10       BASIC 4.0 String-Handling Bug
11       VIC-20 Memory Map
20       Differences Between 9" and 12" CRT, 4000 Series PETs
22       Overview of the CBM 64k Memory Expansion Board
23       Communication using the CBM 8032 and 8010 Modem
25       Machine Language Monitor Commands


Disk Systems and DOS

28       DOS 1.0 Bug Notes (2040)
30       DOS 2.1 and 2.5 Bug Notes (4040-8050)
34       Relative Record File-handling Bug
35       Notes on the Various DOS Versions


Miscellaneous Info

42       4022P Bi-directional Printer ROM Upgrade
44       Signal Format on C2N Cassette Units
49       PET/CBM Rom Genealogy



---- page 49 ----
                      Commodore ROM Genealogy


    When the PET-2001 first went into production in September 1977
there were two ROM sets incorporated into the system, known as BASIC
1.0. One set was the 6540 28-pin ROM by MOS Technology, Inc. and the
other was the 2316 24-pin ROM.

    The next up-grade production was with two ROM sets known as BASIC
2.0. These corrected an intermittent bug in the edit software and
improved the garbage collection routines.

    The next two production ROM sets are generally known as BASIC 3.0.
This up-grade allowed interfacing to the Commodore disk system. It
also cleared up a bug limiting the dimensions on arrays and improved
the garbage collection.

Also, at this time the CBM Professional Computer came into being. One
set of ROM's was for the Graphic (PET) keyboard and the other was for
the Business CBM.

    The next up-grade known as BASIC 4.0 added the Disk Commands to ROM
and greatly improved the garbage collection. This has been further
upgraded to BASIC 4.1 to correct errors in version 4.0. At the same
time Commodore brought out the new 80-column machine (the 8032) with
an enhanced screen editor.

    There have been three different Character Genrerator ROM's
installed over these generations. Earlier production runs through
BASIC 2.0 had the 6540-010 (p/n 901439-08) and 901447-08 (p/n
901447-08), BASIC 3.0 and 4.0 used the 901447-10 (p/n 901447-10).

    The 901447-10 ROM can replace the 901447-08 ROM in up-grading from
BASIC 2.0 to BASIC 3.0. There is no replacement ROM for the 6540-010
28 pin ROM.

    The 2022 (tractor feed model) and 2023 (friction feed) printers
were discontinued in 1980.


---- page 50 ----

    ROM 1.0 - Basic Level I - 28 pin ROM type 6540 - Series 2001

           Location            ROM #              Part Number

              H1             6540-011              901439-01
              H2             6540-013              901439-02
              H3             6540-015              901439-03
              H4             6540-016              901439-04
              H5             6540-012              901439-05
              H6             6540-014              901439-06
              H7             6540-018              901439-07
              A2             6540-010              901439-08

----------------------------------------------------------------------

    ROM 1.0 - Basic Level I - 24 pin ROM type 2316B - Series 2001

           Location            ROM #              Part Number

              H1             901447-01             901447-01
              H2             901447-03             901447-03
              H3             901447-05             901447-05
              H4             901447-06             901447-06
              H5             901447-02             901447-02
              H6             901447-04             901447-04
              H7             901447-07             901447-07
              A2             901447-08             901447-08

----------------------------------------------------------------------

    ROM 2.0 - Basic Level II - 28 pin ROM type 6540 - Series 2001

          Location            ROM #              Part Number

             H1             6540-019              901439-09
             H2             6540-013              901439-02
             H3             6540-015              901439-03
             H4             6540-016              901439-04
             H5             6540-012              901439-05
             H6             6540-014              901439-06
             H7             6540-018              901439-07
             A2             6540-010              901439-08

----------------------------------------------------------------------

    ROM 2.0 - Basic Level II - 24 pin ROM type 2316B - Series 2001

           Location            ROM #              Part Number

              H1             901447-09             901447-09
              H2             901447-03             901447-03
              H3             901447-05             901447-05
              H4             901447-06             901447-06
              H5             901447-02             901447-02
              H6             901447-04             901447-04
              H7             901447-07             901447-07
              A2             901447-08             901447-08


---- page 51 ----

    ROM 3.0 - BASIC Level III - 28 pin ROM type 6540 - Series 2001

           Location            ROM #              Part Number

              H1             6540-020              901439-13
              H2             6540-022              901439-15
              H3             6540-024              901439-17
              H4             6540-025              901439-18
              H5             6540-021              901439-14
              H6             6540-023              901439-16
              H7             6540-026              901439-19
              A2             6540-010              901439-08

----------------------------------------------------------------------

    ROM 3.0 - Basic Level III - 24 pin ROM type 2316B - Series 2001

           Location            ROM #              Part Number

              H1             901465-01             901465-01
              H2             901465-02             901465-02
              H3             901465-24             901465-24
              H4             901465-03             901465-03
              H5               Blank
              H6               Blank
              H7               Blank
              A2             901447-08             901447-08

----------------------------------------------------------------------

    ROM 3.0 - Basic Level III - Large Graphic Keyboard - Series 2001

           Location            ROM #              Part Number

              D3               Blank
              D4               Blank
              D5               Blank
              D6             901465-01             901465-01
              D7             901465-02             901465-02
              D8             901465-24             901465-24
              D9             901465-03             901465-03
              F10            901447-10             901447-10

----------------------------------------------------------------------

        ROM 3.0 - Basic Level III - Business Keyboard - Series 2001

           Location            ROM #              Part Number

              D3               Blank
              D4               Blank
              D5               Blank
              D6             901465-01             901465-01
              D7             901465-02             901465-02
              D8             901474-01             901474-01
              D9             901465-03             901465-03
              F10            901447-10             901447-10

----------------------------------------------------------------------


---- page 52 ----

   ROM 4.0 - Basic Level IV - Graphic Keyboard - Series 2001 & 4000

           Location            ROM #              Part Number

              D3               Blank
              D4               Blank
              D5             901465-19             901465-19
              D6             901465-20             901465-20
              D7             901465-21             901465-21
              D8             901447-29             901447-29
              D9             901465-22             901465-22
              F10            901447-10             901447-10

----------------------------------------------------------------------

   ROM 4.0 - Basic Level IV - Business Keyboard - Series 2001 & 4000

           Location            ROM #              Part Number

              D3               Blank
              D4               Blank
              D5             901465-19             901465-19
              D6             901465-20             901465-20
              D7             901465-21             901465-21
              D8             901474-02             901474-02
              D9             901465-22             901465-22
              F10            901447-10             901447-10

----------------------------------------------------------------------

    ROM 4.1 - Basic Level IV - Graphic Keyboard - Series 2001 & 4000

           Location            ROM #              Part Number

              D3               Blank
              D4               Blank
              D5             901465-23             901465-23
              D6             901465-20             901465-20
              D7             901465-21             901465-21
              D8             901447-29             901447-29
              D9             901465-22             901465-22
              F10            901447-10             901447-10

----------------------------------------------------------------------

   ROM 4.1 - Basic Level IV - Graphic Keyboard - Series 2001 & 4000

           Location            ROM #              Part Number

              D3               Blank
              D4               Blank
              D5             901465-23             901465-23
              D6             901465-20             901465-20
              D7             901465-21             901465-21
              D8             901474-02             901474-02
              D9             901465-22             901465-22
              F10            901447-10             901447-10

----------------------------------------------------------------------


---- page 53 ----

                 ROM 4.0 - Basic Level IV - Series 8000

           Location            ROM #              Part Number

             UD6             901465-22             901465-22
             UD7             901474-03             901474-03
             UD8             901465-21             901465-21
             UD9             901465-20             901465-20
             UD10            901465-19             901465-19
             UD11              Blank
             UD12              Blank
             F10             901447-10             901447-10


----------------------------------------------------------------------

                 ROM 4.1 - Basic Level IV - Series 8000

           Location            ROM #              Part Number

             UD6             901465-22             901465-22
             UD7             901474-03             901474-03
             UD8             901465-21             901465-21
             UD9             901465-20             901465-20
             UD10            901465-23             901465-23
             UD11              Blank
             UD12              Blank
             F10             901447-10             901447-10


----------------------------------------------------------------------

                   VIC-20  COLOR  (Pre-FCC Version)

           Location            ROM #              Part Number

             D5              901486-01             901486-01
             D6              901486-06             901486-06
             C7              901460-03             901460-03

----------------------------------------------------------------------

                     VIC-20  COLOR  (FCC Version)

           Location            ROM #              Part Number

             E11             901486-01             901486-01
             E12             901486-06             901486-06
             D7              901460-03             901460-03

----------------------------------------------------------------------


---- page 54 ----

                          2022 (Tractor Feed) Printer

               Location          ROM #            Part Number

                   U11            901472-03             901472-03

----------------------------------------------------------------------

                          2023 (Friction Feed) Printer

               Location          ROM #            Part Number

                   U11            901472-02             901472-02

----------------------------------------------------------------------

                         2023 Printer - Interim Fix

               Location          ROM #            Part Number

                 U11            901472-03               901472-03

----------------------------------------------------------------------

                      2022 and 2023 Printers - Interim Fix

               Location          ROM #            Part Number

                 U11            901472-03               901472-03

----------------------------------------------------------------------

                       2022 and 2023 Printers - Final Fix

               Location          ROM #            Part Number

                 U11            901472-07               901472-07

----------------------------------------------------------------------

                          4022 (Tractor Feed) Printer

               Location          ROM #            Part Number

                 U11            901472-04               901472-07
[NB: this is probably a misprint]

----------------------------------------------------------------------

--- page 56 --- [page 55 is identical to page 54]

                      D. O. S.   1.0  --  2040 Dual Disk Unit

               Location          ROM #            Part Number

                   UL1            901468-06             901468-06
                   UK1              Blank
                   UH1            901468-07             901468-07
                   UK3            901466-02             901466-02
                   UK6            901467                901467

----------------------------------------------------------------------

                      D. O. S.   2.1  --  4040 Dual Disk Unit

               Location          ROM #            Part Number

                   UL1            901468-12             901468-12
                   UK1            901468-11             901468-11
                   UH1            901468-13             901468-13
                   UK3            901466-04             901466-04
                   UK6            901467                901467

----------------------------------------------------------------------

                 D. O. S.   2.5  --  8050 Dual Disk (Micropolis)

               Location          ROM #            Part Number

                   UL1            901482-03             901482-03
                   UH1            901482-04             901482-04
                   UK3            901483-03             901483-03
                   UK6            901467                901467

----------------------------------------------------------------------

                    D. O. S.   2.5  --  8050 Dual Disk (Tandon)

               Location          ROM #            Part Number

                   UL1            901482-07             901482-07
                   UH1            901482-06             901482-06
                   UK3            901483-04             901483-04
                   UK6            901467                901467

----------------------------------------------------------------------

                    D. O. S.   2.6  --  2031 Single Disk Drive

               Location          ROM #            Part Number

                   U5F            901484-05             901484-05
                   U5H            901484-03             901484-03

----------------------------------------------------------------------


-- Mark
