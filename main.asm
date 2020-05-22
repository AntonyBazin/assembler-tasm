    .model medium; поскольку разбили прогу на 2 файла, все процедуры дальнего вызова, 2 сегмента кода
    .stack 100h
public	start; должны транслировать метку старт, сделать её доступной, это точка входа, что =бы ред связи оттранслировал и она была доступна в остальных модулях
extrn	items:byte; все данные помечены как внешние
extrn	fn:byte; строки/ буферы для хранения строк
extrn	ibuf:byte; ввод сюда
extrn	obuf:byte; вывод через это
extrn	msg:byte
extrn	frm:byte
extrn	qws:byte
extrn	inp:byte
extrn	bye:byte
extrn	input:far; метки вызова процедур
extrn	inputline:far; far = 2 слова
extrn	readfile:far
extrn	output:far
extrn	writefile:far
extrn	menu:far
extrn	algorithm:far
	.code
start:	mov ax,@data; это точк входа в программу      программа многосегментная, требуется имя. имя файла_текст
	mov ds,ax
	mov es,ax
	cld; бдут использоваться цепочечные команды
m1:	mov ax,5; должны вывести на экран меню: считать данные с клавы, с файла, ...
	push offset items; второй параметр через стек, фактически это перечень альтернатив и приглашение ввести номер альтернативы
	call menu; обеспечивает вывод, принимает 2 параметра через ax - количество пунктов
	pop bx; очистил стек от переданных параметров 
	jnc m2; в случае любых ошибок - установки CF - ошибка, если ошбиок не было - выбираем альтернативу
	push offset msg
	call output
	pop bx
	jmp m10
m2:	cmp ax,1; выбрана ли первая альтенатива? то есть ввод инфы с клавиатуры
	jne m3
	push offset inp
	call output; выведет сообщение приглашение ввыода строки
	pop bx; осчистили стек
	push offset ibuf; смещение буфера
	call input; вводит текст, закроет его нулем, до пустой строки вводит
	pop bx; освб. стек
	jc m4;ошибка ввода, по сути это прыжок на метку 11, там вывод сбщ об ошибке
	jmp m1; если всё ок то прыгаем на метку 1
m3:	cmp ax,2; выбрана ли альтернатива 2? -- вовод инормации из файла
	jne m5; прыгаем на 5, если не 2
	push offset qws; прглашение на ввод имени файла
	call output
	pop bx; освб стек
	push offset fn; запустили ввод имени файла
	call inputline; вводит только 1 строку
	pop bx
	jc m4; если ошибка то на метку 4
	push offset fn; процедура ввода данных, 2 параметра - имя файла и буфер
	push offset ibuf
	call readfile; закроет буфер 0
	pop bx
	pop bx
	jc m4; ошибки - на обработку ошибок
	jmp m1; если 
m4:	jmp m11
m5:	cmp ax,3; выбрана ли альтернатива 3?
	jne m6
	push offset obuf; вывод до 0-байта
	call output
	pop bx
	jc m4; обработка ошибок
	jmp m1
m6:	cmp ax,4; выбран пункт 4? вывод информации в файл
	jne m7
	push offset qws; спрашиваем имя файла
	call output
	pop bx
	push offset fn; ввести строку с клавиатуры
	call inputline
	pop bx
	jc m11; снова в случае ошибки можно прыгать на 11 с ошибкой
	push offset fn; тут имя файла
	push offset obuf; тут инфа чтобы вывести
	call writefile; выводим
	pop bx
	pop bx
	jc m11; если с ошибкой
	jmp m1; снова показываем меню
m7:	cmp ax,5; 51 пункт меню - запуск алгоритма
	jne m9 ; 1 пар - входной буфер, 2й - выходной
	push offset obuf
	push offset ibuf
	call algorithm
	pop bx
	pop bx
	jc m8; если ошибка в алгоритме, связана с некорректной инфой в буфере
	jmp m1
m8:	push offset frm
	call output
	pop bx
	jmp m1
m9:	push offset bye; если не выбран никаккой пункт, значит, это 0, то завершаем работу
	call output
	add sp,2; по другому очистили стек, вообще можно даже внутри процедуры освобождать через ret
m10:	mov ax,4c00h; завершение программы
	int 21h
m11:	push offset msg; сообщение об ошибке
	call output
	pop bx
	jmp m1
	end start
