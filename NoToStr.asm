; Andrius Šukys
; Programa, kuri visus faile rastus skaitmenis pakeičia žodžiais („1“ -> „one“,...) ir rezultatą išsaugo kitame faile.

.MODEL small	; Nurodoma, kokio dydžio bus programinis kodas

    skBufDydis	EQU 20	; Konstanta, skaitymo buferio dydis
	raBufDydis	EQU 255	; Konstanta, rašymo buferio dydis
    
.stack 100h	; Apibrėžiama, kad bus naudojamas stekas, 100h (256 baitų) dydžio

.data	; Pažymime, kad nuo čia prasidės duomenų segmentas

	zero   db 'zero'	; Aprašomi skaičių kintamieji
    one	   db 'one'		; Aprašomi skaičių kintamieji
    two    db 'two'		; Aprašomi skaičių kintamieji
    three  db 'three'	; Aprašomi skaičių kintamieji
    four   db 'four'	; Aprašomi skaičių kintamieji
    five   db 'five'	; Aprašomi skaičių kintamieji
    six    db 'six'		; Aprašomi skaičių kintamieji
    seven  db 'seven'	; Aprašomi skaičių kintamieji
    eight  db 'eight'	; Aprašomi skaičių kintamieji
    nine   db 'nine'	; Aprašomi skaičių kintamieji
	
	duom	    db 100 dup(0)	; Vieta, į kurią bus rašomas duomenų failo pavadinimas iš komandinės eilutės
	rez     	db 100 dup(0)	; Vieta, į kurią bus rašomas rezultatų failo pavadinimas iš komandinės eilutės
	
	skBuf		db skBufDydis dup (?)	; Skaitymo buferis
	raBuf		db raBufDydis dup (?)	; Rašymo buferis
	
	duomDesk	dw ?	; Vieta, kur bus saugomas duomenų failo deskriptoriaus numeris
	rezDesk		dw ?	; Vieta, kur bus saugomas rezultatų failo deskriptoriaus numeris
	
	; Aprašomas pagalbos pranešimo kintamasis
    pagalbos_pranesimas	db 'The program converts the numbers in the data file into words and', 10, 13, 'outputs them to another file. Please provide a data file.', 10, 13, 'To run the program correctly, enter the name of the program,', 10, 13, 'data and results filenames, e.g. <NoToStr.exe> <data.txt> <res.txt>'
	; Aprašomas pabaigos pranešimo kintamasis
	pabaigos_pranesimas db 'Results were written to the desired file.', 10, 13, 'The program terminated with success.'
	
	; Aprašomi galimų klaidų kintamieji
	klaida_1 db 'Could not open the data file for reading. The program terminated.'
	klaida_2 db 'Could not open the result file for writing. The program terminated.'
	klaida_3 db 'Failed to close the result file. The program terminated.'
	klaida_4 db 'Failed to close the data file. The program terminated.'
	klaida_5 db 'Failed to read data from file to buffer. The program terminated.'
	klaida_6 db 'Data has only been written partially. The program terminated.'
	klaida_7 db 'An error occurred while writing to the file. The program terminated.'
	
.code    	;	Prasideda kodo segmentas       
CodeStart:	; Žymeklis, kuris pažymi, kad čia prasideda kodas
    Programa:
  
    MOV	ax, @data	; Į AX registrą priskiriame duomenų segmento pradžios vietą atmintyje
	MOV	ds, ax		; Į duomenų segmentą DS perkeliame AX reikšmę, kad DS rodytų į duomenų segmento pradžią
    MOV si, 0		; SI reikšmei priskiriamas 0
    MOV di, 0		; DI reikšmei priskiriamas 0
  
; DARBAS SU PALEIDIMO PARAMETRAIS. IEŠKOMA PAGALBOS PRAŠYMO IR NUSKAITOMI DUOMENŲ IR REZULTATŲ FAILŲ PAVADINIMAI

	MOV bx, 80h			; BX reikšmei priskiriamas 80h
	MOV ch, 0			; CH reikšmei priskiriamas 0
	MOV cl, es:[bx]		; Į CL perkeliamas programos paleidimo parametrų simbolių skaičius, kuris rašomas ES segmento 80h baite
	CMP cx, 0			; Jeigu CX yra lygus nuliui,
	JE ReikiaPagalbos	; tai tuomet reikia išvesti pagalbos pranešimą, nes nebuvo nurodyti jokie parametrai
	
	INC bx	; BX reikšmė padidinama vienetu, nes programos paleidimo parametrai rašomi segmente ES pradedant 81h baitu
	
	IeskotiPagalbos:	
	CMP es:[bx], '?/'		; ES segmente su poslinkiu BX ieškoma '?/' (atmintyje jaunesnysis baitas saugomas pirmiau, todėl pirmasis įrašomas į BL, antrasis - į AH, todėl '/?' virsta '?/'
	JE ReikiaPagalbos		; Jeigu randamas '?/', šokama į žymę ReikiaPagalbos
	INC bx					; Jeigu '?/' nerastas, BX reikšmė padidinama vienetu, t.y. paslenkama rodyklė ir tikrinami toliau esantys parametrai
	LOOP IeskotiPagalbos	; Jei nepatikrinti visi parametrai, reikia tikrinti toliau
	
	MOV bx, 81h	; Patikrinus parametrus, grįžtama į 81h baitą, kad juos būtų galima užrašyti į vietas, kuriose yra duomenų ir rezultatų failų pavadinimų kintamieji
	
    ParametruTikrinimas:
    MOV ax, es:[bx]			; Į AX perkeliama ES reikšmė su poslinkiu BX
    CMP al, 13				; Tikrinama, ar AL esantis simbolis yra Carriage Return
    JE  ArParametraiIvesti	; Jeigu taip, šokama į žymę ArParametraiIvesti, t.y., tikrinama, ar buvo įvesti visi reikiami paleidimo parametrai komandinėje eilutėje
 
    TikrintiDuomenuFailoParametra:
    MOV ax, es:[bx]	; Į AX perkeliama ES reikšmė su poslinkiu BX
    CMP al, ' '		; Tikrinama, ar AL esantis simbolis yra tarpas
	JE  TikrintiRezultatuFailoParametra	; Jeigu taip, tai reiškia, kad duomenų parametras buvo įvestas ir kad dabar vedamas rezultatų failo parametras, todėl šokama į žymę TikrintiRezultatuFailoParametra
    CMP al, 13		; Jeigu įvedus duomenų failo parametrą, bet neįvedus rezultatų failo parametro AL įgauna reikšmę Carriage Return, išvedamas pagalbos pranešimas          
    JE  ReikiaPagalbos	; Šokama į žymę ReikiaPagalbos, kur bus išvestas pagalbos pranešimas
    MOV [duom + si], al	; Į duomenų failo pavadinimo kintamąjį su poslinkiu SI perkeliama AL reikšmė
	INC bx			; BX reikšmė padidinama vienetu
    INC si			; SI reikšmė padidinama vienetu
    JMP TikrintiDuomenuFailoParametra	; Šokama į žymę TikrintiDuomenuFailoParametra, kad būtų galima nuskaityti tolimesnius simbolius parametre

    TikrintiRezultatuFailoParametra:
    INC bx				; BX reikšmė padidinama vienetu           
    CMP bx, 82h			; Jeigu BX reikšmė lygi 82h (ES baito numeris)          
    JE  ParametruTikrinimas	; Tuomet šokama į žymę ParametruTikrinimas, norint patikrinti, ar buvo įvestas duomenų failo parametras
    MOV ax, es:[bx]		; Į AX perkeliama ES reikšmė su poslinkiu BX
    CMP al, 13d			; Tikrinama, ar AL esantis simbolis yra Carriage Return
    JE  ArParametraiIvesti	; Jeigu taip, tikrinama, ar buvo įvesti visi reikalingi paleidimo parametrai
    MOV [rez + di], al	; Į rezultatų failo pavadinimo kintamąjį su poslinkiu DI perkeliama AL reikšmė
    INC di				; DI reikšmė padidinama vienetu
    JMP TikrintiRezultatuFailoParametra	; Šokama į žymę TikrintiRezultatuFailoParametra, kad būtų galima nuskaityti tolimesnius simbolius parametre
 
    ReikiaPagalbos:
    MOV dx, offset pagalbos_pranesimas	; Nuoroda į vietą atmintyje, kur užrašytas pagalbos pranešimas
    MOV cx, 254							; Į CX įdedama reikšmė, nurodanti, kiek baitų reikia išvesti
    CALL SpausdintiIEkrana				; Kreipinys į spausdinimo ekrane funkciją
    JMP Pabaiga							; Šokama į žymę Pabaiga
 
    ArParametraiIvesti:
    CMP duom, 0			; Tikrinama, ar duomenų failo kintamojo reikšmė 0
    JE ReikiaPagalbos	; Jeigu taip, tuomet trūksta duomenų failo parametro, reikia išvesti pagalbos pranešimą
    CMP rez, 0			; Tikrinama, ar rezultatų failo kintamojo reikšmė 0
    JE ReikiaPagalbos	; Jeigu taip, tuomet trūksta rezultatų failo parametro, reikia išvesti pagalbos pranešimą
	
; DUOMENŲ FAILO ATIDARYMAS SKAITYMUI
	MOV	ah, 3Dh			; 21h pertraukimo failo atidarymo funkcijos numeris
	MOV	al, 00			; Jei AL = 00, tai failas atidaromas skaitymui			         
	MOV	dx, offset duom	; Vieta, kur nurodomas failo pavadinimas, kuris baigiasi nuliniu simboliu
	INT 21h				; Failas atidaromas skaitymui
	JC	KlaidaAtidarantSkaitymui	; Jei atidarant failą skaitymui įvyksta klaida, nustatomas Carry Flag, tokiu atveju šokama į klaidos žymę
	MOV	duomDesk, ax	; Atmintyje išsisaugome duomenų failo deskriptoriaus numerį
	
; REZULTATŲ FAILO SUKŪRIMAS IR ATIDARYMAS RAŠYMUI
	MOV	ah, 3Ch			; 21h pertraukimo failo sukūrimo funkcijos numeris
	MOV	cx, 0			; Kuriamo failo atributai (šiuo atveju - read-only)
	MOV	dx, offset rez	; Vieta, kur nurodomas failo pavadinimas, kuris baigiasi nuliniu simboliu
	INT	21h				; Failas sukuriamas; jeigu toks failas jau egzistuoja, jame ištrinama visa esanti informacija
	JC	KlaidaAtidarantRasymui	; Jeigu kuriant failą rašymui įvyksta klaida, nustatomas Carry Flag, tokiu atveju šokama į klaidos žymę
	MOV	rezDesk, ax		; Atmintyje išsisaugome rezultatų failo deskriptoriaus numerį
	
; DUOMENŲ NUSKAITYMAS IŠ FAILO Į BUFERĮ
	DuomenuNuskaitymas:                     
    MOV bx, duomDesk		; Į BX įkeliamas duomenų failo deskriptoriaus numeris
    CALL SkaitytiIBuferi	; Kreipinys į skaitymo iš failo procedūrą
    CMP ax, 0				; Į AX įrašoma, kiek baitų nuskaityta, jeigu reikšmė lygi 0, tai pasiekta failo pabaiga
    JNE EitiToliau

    JMP UzdarytiRasymui		; Jeigu pasiekta failo pabaiga, tai šokama į žymę UzdarytiRasymui

EitiToliau:
; DARBAS SU NUSKAITYTA INFORMACIJA
    MOV bx, ax				; Į BX įrašoma, kiek baitų buvo nuskaityta skaitymo iš failo procedūroje (ta reikšmė yra AX)
    MOV si, offset skBuf	; Į SI registrą perkeliamas DS segmento poslinkis iki skaitymo buferio
	MOV di, offset raBuf	; Į DI registrą perkeliamas DS segmento poslinkis iki rašymo buferio
	MOV dx, 0				; DX suteikiama reikšmė 0
	CALL TikrintiIrKeisti	; Kreipinys į procedūrą, skirtą skaičių keitimui į žodžius
	MOV cx, dx				; Į CX perkeliama DX reikšmė
	CALL IrasytiIFaila		; Kreipinys į procedūrą, skirtą išvesti rašymo buferį į failą
    JMP DuomenuNuskaitymas	; Šokama į žymę DuomenuNuskaitymas, kad būtų galima nuskaityti kitus duomenis į duomenų buferį
	
; REZULTATŲ FAILO UŽDARYMAS
	UzdarytiRasymui:
	MOV	ah, 3Eh			; 21h pertraukimo failo uždarymo funkcijos numeris				
	MOV	bx, rezDesk		; Į BX įrašomas rezultato failo deskriptoriaus numeris		
	INT	21h				; Failo uždarymas			
	JC	KlaidaUzdarantRasymui	; Jeigu uždarant failą įvyksta klaida, nustatomas Carry Flag, tokiu atveju šokama į klaidos žymę	

; DUOMENŲ FAILO UŽDARYMAS
	UzdarytiSkaitymui:
	MOV	ah, 3Eh			; 21h pertraukimo failo uždarymo funkcijos numeris				
	MOV	bx, duomDesk	; Į BX įrašomas duomenų failo deskriptoriaus numeris			
	INT	21h				; Failo uždarymas				
	JC	KlaidaUzdarantSkaitymui	; Jeigu uždarant failą įvyksta klaida, nustatomas Carry Flag, tokiu atveju šokama į klaidos žymę		

; PROGRAMOS PABAIGA IR PABAIGOS ŽINUTĖ

	MOV dx, offset pabaigos_pranesimas  ; Nuoroda į vietą atmintyje, kur yra pabaigos žinutė
	MOV cx, 79							; Į CX įrašoma, kiek baitų reikia išvesti
	CALL SpausdintiIEkrana				; Kreipinys į spausdinimo ekrane funkciją
	    
	Pabaiga:
  	MOV	ah, 4Ch	; Programos pabaigos funkcija		
	MOV	al, 0	; AL suteikiama reikšmė 0
	INT	21h	 	; Baigiamas programos darbas
  
; KLAIDŲ APDOROJIMAS
	
	KlaidaAtidarantSkaitymui:
	MOV dx, offset klaida_1	; Nuoroda į vietą atmintyje, kur užrašytas klaidos pranešimas
    MOV cx, 65				; Į CX įrašoma, kiek baitų reikia išvesti
    CALL SpausdintiIEkrana	; Kreipinys į spausdinimo ekrane funkciją
	JMP	Pabaiga   			; Šokama į pabaigos žymę
	
	KlaidaAtidarantRasymui:
	MOV dx, offset klaida_2 ; Nuoroda į vietą atmintyje, kur užrašytas klaidos pranešimas
    MOV cx, 67				; Į CX įrašoma, kiek baitų reikia išvesti
    CALL SpausdintiIEkrana	; Kreipinys į spausdinimo ekrane funkciją
	JMP	UzdarytiSkaitymui   ; Šokama į duomenų failo uždarymo žymę
	
	KlaidaUzdarantRasymui:
    MOV dx, offset klaida_3 ; Nuoroda į vietą atmintyje, kur užrašytas klaidos pranešimas
    MOV cx, 56				; Į CX įrašoma, kiek baitų reikia išvesti
    CALL SpausdintiIEkrana	; Kreipinys į spausdinimo ekrane funkciją
	JMP	UzdarytiSkaitymui	; Šokama į duomenų failo uždarymo žymę

	KlaidaUzdarantSkaitymui:
	MOV dx, offset klaida_4 ; Nuoroda į vietą atmintyje, kur užrašytas klaidos pranešimas
    MOV cx, 54				; Į CX įrašoma, kiek baitų reikia išvesti
    CALL SpausdintiIEkrana	; Kreipinys į spausdinimo ekrane funkciją
	JMP Pabaiga				; Šokama į pabaigos žymę
  
; NAUDOJAMOS PROCEDŪROS

; PROCEDŪRA, LYGINANTI SIMBOLĮ SU SKAIČIUMI IR PAVERČIANTI JĮ ŽODŽIU (VISAM DUOMENŲ BUFERIUI)
TikrintiIrKeisti PROC	; Pažymima procedūros pradžia
	
	Kartoti:			; Žymė procedūros kartojimui
	CMP bx, 0			; BX reikšmė lyginama su 0
	JA KitasSimbolis	; Jeigu BX > 0, tai šokama į žymę KitasSimbolis, nes dar yra simbolių, kuriuos reikia apdoroti
	
	RET		; Jeigu BX = 0, tai nešokama į žymę KitasSimbolis ir grįžtama iš procedūros
	
	KitasSimbolis:
    MOV al, ds:[si]	; Į AL perkeliamas simbolis, esantis DS segmente su poslinkiu SI
	
    CMP al, '0'		; Tikrinama, ar AL esantis simbolis lygus '0'
    JE Pakeisti_0	; Jeigu taip, šokama į žymę Pakeisti_0
    CMP al, '1'		; Tikrinama, ar AL esantis simbolis lygus '1'
    JE Pakeisti_1  	; Jeigu taip, šokama į žymę Pakeisti_1
    CMP al, '2'		; Tikrinama, ar AL esantis simbolis lygus '2'
    JE Pakeisti_2	; Jeigu taip, šokama į žymę Pakeisti_2
    CMP al, '3'		; Tikrinama, ar AL esantis simbolis lygus '3'
    JE Pakeisti_3  	; Jeigu taip, šokama į žymę Pakeisti_3
    CMP al, '4'		; Tikrinama, ar AL esantis simbolis lygus '4'
    JE Pakeisti_4	; Jeigu taip, šokama į žymę Pakeisti_4
    CMP al, '5'		; Tikrinama, ar AL esantis simbolis lygus '5'
    JE Pakeisti_5  	; Jeigu taip, šokama į žymę Pakeisti_5
    CMP al, '6'		; Tikrinama, ar AL esantis simbolis lygus '6'
    JE Pakeisti_6	; Jeigu taip, šokama į žymę Pakeisti_6
    CMP al, '7'		; Tikrinama, ar AL esantis simbolis lygus '7'
    JE Pakeisti_7	; Jeigu taip, šokama į žymę Pakeisti_7
    CMP al, '8'		; Tikrinama, ar AL esantis simbolis lygus '8'
    JE Pakeisti_8	; Jeigu taip, šokama į žymę Pakeisti_8
    CMP al, '9'		; Tikrinama, ar AL esantis simbolis lygus '9'
    JE Pakeisti_9 	; Jeigu taip, šokama į žymę Pakeisti_9
	
	; Jeigu simbolį palyginus su visais įmanomais skaičiais nustatoma, kad tai nėra skaičius, reiškia, kad tai - simbolis
    MOV [di], al	; Į duomenų segmentą su poslinkiu DI (kur yra rašymo buferis) perkeliama AL reikšmė
    INC di			; DI reikšmė padidinama vienetu (kad iškart būtų galima įrašyti kitą simbolį)
	INC dx			; DX reikšmė padidinama vienetu (DX'e skaičiuojama, kiek simbolių įvesta į rašymo buferį)
	JMP Simboliams	; Šokama į žymę Simboliams (ji nuo skaičių žymės skiriasi tuo, kad iš steko nėra išimamas SI, nes įrašant simbolius jis nėra į jį įdedamas)
	
    Pakeisti_0:
	PUSH si					; SI reikšmė įdedama į steką
    MOV si, offset zero		; Nuoroda į vietą atmintyje, kur užrašytas žodis 'zero'
    MOV cx, 4            	; Į CX įrašoma, kiek baitų reikia užrašyti į rašymo buferį
    JMP RasytiIBuferi		; Šokama į žymę RasytiIBuferi
    Pakeisti_1:
	PUSH si					; SI reikšmė įdedama į steką
    MOV si, offset one		; Nuoroda į vietą atmintyje, kur užrašytas žodis 'one'
    MOV cx, 3              	; Į CX įrašoma, kiek baitų reikia užrašyti į rašymo buferį
    JMP RasytiIBuferi 		; Šokama į žymę RasytiIBuferi
    Pakeisti_2:
	PUSH si					; SI reikšmė įdedama į steką
    MOV si, offset two		; Nuoroda į vietą atmintyje, kur užrašytas žodis 'two'
    MOV cx, 3              	; Į CX įrašoma, kiek baitų reikia užrašyti į rašymo buferį
    JMP RasytiIBuferi		; Šokama į žymę RasytiIBuferi
    Pakeisti_3:
	PUSH si					; SI reikšmė įdedama į steką
    MOV si, offset three	; Nuoroda į vietą atmintyje, kur užrašytas žodis 'three'
    MOV cx, 5				; Į CX įrašoma, kiek baitų reikia užrašyti į rašymo buferį
    JMP RasytiIBuferi       ; Šokama į žymę RasytiIBuferi
    Pakeisti_4:
	PUSH si					; SI reikšmė įdedama į steką
    MOV si, offset four		; Nuoroda į vietą, kur užrašytas žodis 'four'
    MOV cx, 4				; Į CX įrašoma, kiek baitų reikia užrašyti į rašymo buferį
    JMP RasytiIBuferi		; Šokama į žymę RasytiIBuferi
    Pakeisti_5:
	PUSH si					; SI reikšmė įdedama į steką
    MOV si, offset five		; Nuoroda į vietą, kur užrašytas žodis 'five'
    MOV cx, 4				; Į CX įrašoma, kiek baitų reikia užrašyti į rašymo buferį
    JMP RasytiIBuferi		; Šokama į žymę RasytiIBuferi
    Pakeisti_6:
	PUSH si					; SI reikšmė įdedama į steką
    MOV si, offset six		; Nuoroda į vietą, kur užrašytas žodis 'six'
    MOV cx, 3				; Į CX įrašoma, kiek baitų reikia užrašyti į rašymo buferį
    JMP RasytiIBuferi		; Šokama į žymę RasytiIBuferi
    Pakeisti_7:
	PUSH si					; SI reikšmė įdedama į steką
    MOV si, offset seven	; Nuoroda į vietą, kur užrašytas žodis 'seven'
    MOV cx, 5				; Į CX įrašoma, kiek baitų reikia užrašyti į rašymo buferį
    JMP RasytiIBuferi		; Šokama į žymę RasytiIBuferi
    Pakeisti_8:
	PUSH si					; SI reikšmė įdedama į steką
    MOV si, offset eight	; Nuoroda į vietą, kur užrašytas žodis 'eight'
    MOV cx, 5				; Į CX įrašoma, kiek baitų reikia užrašyti į rašymo buferį
    JMP RasytiIBuferi		; Šokama į žymę RasytiIBuferi
    Pakeisti_9:
	PUSH si					; SI reikšmė įdedama į steką
    MOV si, offset nine		; Nuoroda į vietą, kur užrašytas žodis 'nine'
    MOV cx, 4 				; Į CX įrašoma, kiek baitų reikia užrašyti į rašymo buferį
    JMP RasytiIBuferi		; Šokama į žymę RasytiIBuferi
    
	RasytiIBuferi:
	CMP cx, 0				; Tikrinama, ar CX reikšmė lygi 0,
	JE RasytiIBuferiPabaiga	; jei taip, šokama į žymę RasytiIBuferiPabaiga
	MOV al, [si]			; Į AL perkeliama duomenų segmento reikšmė su poslinkiu SI (iš duomenų buferio į AL)
	MOV [di], al			; Į duomenų segmentą su poslinkiu DI perkeliama AL reikšmė (iš AL į rezultatų buferį)
	DEC cx					; CX reikšmė sumažinama vienetu (joje - kiek simbolių reikia užrašyti rezultatų buferyje)
	INC di					; DI reikšmė padidinama vienetu
	INC si					; SI reikšmė padidinama vienetu
	INC dx					; DX reikšmė padidinama vienetu
	JMP RasytiIBuferi		; Šokama į žymę RasytiIBuferi
	
	RasytiIBuferiPabaiga:
	POP si					; Iš steko išimama SI reikšmė
	Simboliams:
	INC si					; SI reikšmė padidinama vienetu
	DEC bx					; BX reikšmė sumažinama vienetu
	JMP Kartoti				; Šokama į žymę Kartoti
	
TikrintiIrKeisti ENDP	; Pažymima procedūros pabaiga

; PROCEDŪRA, NUSKAITANTI INFORMACIJĄ IŠ FAILO
PROC SkaitytiIBuferi	; Pažymima procedūros pradžia
    PUSH cx	; Į steką įdedama CX reikšmė
    PUSH dx	; Į steką įdedama DX reikšmė
    
    MOV ah, 3Fh				; 21h pertraukimo duomenų nuskaitymo funkcijos numeris
    MOV cx, skBufDydis		; Į CX įrašoma, kiek baitų reikia nuskaityti iš failo 
    MOV dx, offset skBuf	; Vieta, į kurią įrašomi duomenys
    INT 21h					; Skaitymas iš failo
    JC KlaidaSkaitant		; Jei skaitant iš failo įvyksta klaida, nustatomas Carry Flag, tokiu atveju šokama į klaidos žymę
    
	SkaitytiIBuferiPabaiga:
	POP dx	; Iš steko išimama DX reikšmė
	POP cx	; Iš steko išimama CX reikšmė
	RET		; Grįžtama atgal iš procedūros
    
	KlaidaSkaitant:
	MOV dx, offset klaida_5	; Nuoroda į vietą, kur užrašytas klaidos pranešimas
	MOV cx, 64				; Į CX įrašoma, kiek baitų reikia išvesti
	MOV ax, 0				; Pažymime registre AX, kad nebuvo nuskaityta nė vieno simbolio
	CALL SpausdintiIEkrana	; Kreipinys į spausdinimo ekrane funkciją
	JMP SkaitytiIBuferiPabaiga	; Šokama į žymę SkaitytiIBuferiPabaiga
	
SkaitytiIBuferi ENDP	; Pažymima procedūros pabaiga

; PROCEDŪRA, SKIRTA DUOMENIMS Į FAILĄ ĮRAŠYTI
IrasytiIFaila PROC	; Pažymima procedūros pradžia
    PUSH bx	; Į steką įdedama BX reikšmė
	PUSH dx	; Į steką įdedama DX reikšmė
    MOV bx, rezDesk			; Į BX įrašomas failo deskriptoriaus numeris
	MOV dx, offset raBuf	; Nuoroda į vietą, iš kurios rašoma į failą
    MOV ah, 40h				; Rašymo į failą/įrenginį funkcijos numeris
    INT 21h					; Tai, kas yra DX registre, rašoma į failą
	JC KlaidaRasant			; Jeigu rašant į failą įvyksta klaida, nustatomas Carry Flag, tokiu atveju šokama į klaidos žymę
	CMP cx, ax				; Lyginamos CX ir AX reikšmės,
	JNE DalinisIrasymas		; Jeigu jos nelygios - vadinasi įvyko dalinis įrašymas, šokama į klaidos žymę
	
	IrasytiIFailaPabaiga:
	POP dx	; Iš steko išimama DX reikšmė
    POP bx	; Iš steko išimama BX reikšmė
    RET		; Grįžtama atgal iš procedūros
	
	DalinisIrasymas:
	MOV dx, offset klaida_6	; Nuoroda į vietą, kur užrašytas klaidos pranešimas
	MOV cx, 61				; Į CX įrašoma, kiek baitų reikia išvesti
	CALL SpausdintiIEkrana	; Kreipinys į spausdinimo ekrane funkciją
	JMP IrasytiIFailaPabaiga	; Šokama į žymę IrasytiIFailaPabaiga
	
	KlaidaRasant:
	MOV dx, offset klaida_7	; Nuoroda į vietą, kur užrašytas klaidos pranešimas
	MOV cx, 68				; Į CX įrašoma, kiek baitų reikia išvesti
	CALL SpausdintiIEkrana	; Kreipinys į spausdinimo ekrane funkciją
	JMP IrasytiIFailaPabaiga	; Šokama į žymę IrasytiIFailaPabaiga
	
IrasytiIFaila ENDP	; Pažymima procedūros pabaiga

; PROCEDŪRA, SKIRTA SPAUSDINIMUI Į EKRANĄ
SpausdintiIEkrana PROC	; Pažymima procedūros pradžia
    PUSH bx			; Į steką įdedama BX reikšmė
    MOV bx, 1    	; Į BX įrašomas Standart Output įrenginio deskriptoriaus numeris
    MOV ah, 40h		; Rašymo į failą/įrenginį funkcijos numeris
    INT 21h			; DX turinys užrašomas Standart Output'e
    POP bx			; Iš steko išimama BX reikšmė
    RET				; Grįžtama atgal iš procedūros
	
SpausdintiIEkrana ENDP	; Pažymima procedūros pabaiga
	
END CodeStart	; Programos pabaiga