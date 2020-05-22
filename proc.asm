	.model medium
public	inputline,input,readfile,output,writefile,menu,algorithm,words,space,check; метки данного модуля делаем доступными вне модуля
extrn	start:far; Если со стартом - файлы в любом порядке
extrn	delim:byte
extrn	lens:byte
extrn	ptrs:word
extrn	n:word
	.code; другой сегмент кода, тк модел medium, а не compact или small, по умолчанию все метки 4 байта
inputline	proc; ввод строки, принимает 1 параметр, введёт 1 строку и автоматически закроет её 0
	locals @@; локальные метки чтобы не было пересечений
@@buffer	equ [bp+6]; ссылка на локальные параметры, здесь 1 параметр, +6 потому что, первый параметр адрес возврата +2 - смещение, +4 - сегмент
	push bp; sp указывает на 1 занятую ячейку
	mov bp,sp; стандарт, всегда надо делать, чтобы через bp правильно адресоваться
	push ax
	push bx
	push cx
	push dx; сохраняем те регистры, которые будем использовать
	push di; чтобы 13 заменить на 0
	mov ah,3fh; номер функции чтения из файла
	xor bx,bx; адрес файла клавиатуры = 0 , надо его получить
	mov cx,80; боольше 80 символов не ввести
	mov dx,@@buffer; буфер, куда будем заносить инфу
	int 21h; вызываем прерывание, в случае успеха в ax - число введенных символов и сбрасывается CF, в случае ошибки установится CF
	jc @@ex; идём на выход, обработкой ошибок бдет заниматься вызывающая функция, кто вызывал - увидит CF
	cmp ax,80; иначе всё хорошо и в ax сколько символов введено, + 2(13, 10) -- может быть введено ровно 80, если 80 - значит ошибка, имя файла обрубилось хотя бы 79
	jne @@m; переходим 
	stc
	jmp short @@ex
@@m:	mov di,@@buffer; заносим адрес буфера
	dec ax
	dec ax; уменьшаем на 2
	add di,ax; нашли смещения места, где кончается имя файла
	xor al,al; затираем 13шку нуль-байтом, cf тут гарантированно сбрасывается
	stosb; помещает значение al в конец файла, оно оказалось закрыто 0-байтом.
@@ex:	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp; освобождаем стек
	ret; уходим обратно
	endp



input	proc; просто ввод большого числа строк пока не введем пустую строку, после чего весь буфер закроется 0-байтом
	locals @@; она far по умолчанию, метки локальные
@@buffer	equ [bp+6]; куда будет вводиться инфа
	push bp
	mov bp,sp; стандартно чтобы bp показывал куда надо
	push ax
	push bx
	push cx
	push dx
	push di; чтобы искать-закрывать 0-байтом
	xor bx,bx; когда будем вводить строки, должны следить за буфером, , очищаем bx чтобы читаьь с клавы
	mov cx,4095; -1 потому что надо добавить 0-байт, в cx сколько максимально читать
	mov dx,@@buffer; в дх адрес буфера
@@m1:	mov ah,3fh; адрес чтения файла
	int 21h
	jc @@ex; есл cf то выходим с установленным cf
	cmp ax,2; в ax проверяем на пустую строку - 13,10
	je @@m2
	sub cx,ax; вычетаем из cx сколько ввели
	jcxz @@m2; поэтому cx либо 0 либо нет
	add dx,ax; ввод должен начаться с того места, где закончился предыдущий ввод
	jmp @@m1; снова будем читать клаву
@@m2:	mov di,@@buffer; достаточно только найти конец и закрыть его 0.
	add di,4095; знаем, сколько введено, тк вычетали из cx длину введенного, заносим в di начало буфера
	sub di,cx; сколько недоввели, столько и вычетаем
	xor al,al; cf = 0 гарантированно
	stosb; очищаем al и закрываем 0-байтом
@@ex:	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp; корректный выход
	ret
	endp



output	proc; вывод 1 или более строк, ограниченных 0
	locals @@
@@buffer	equ [bp+6]; единственный параметр - буфер инфы которую надо вывести
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	push di; 4 регистра чтобы вызывать функции дос, и 5 чтоб показать на 0 байт
	mov di,@@buffer; вычислить длины выводимой инфы
	xor al,al
	mov cx,0ffffh; в cx max значение
	repne scasb; будет искать в буфере 0-байт(сравнивая с al) не больше чем cx раз
	neg cx; если nullbyte - сразу, то neg cx даст 2, dec dec - дадут корректное значение не включая 0byte
	dec cx
	dec cx
	jcxz @@ex; если 0 то сразу выходим, ничего выводить не надо
	cmp cx,4095; проверяем не оказался ли буфер длиннее чем 4095+0-байт
	jbe @@m; если больше, принудительно выведем только 4095 байт
	mov cx,4095
@@m:	mov ah,40h; запись в файл
	xor bx,bx
	inc bx; заносим 1
	mov dx,@@buffer
	int 21h
@@ex:	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp; после этого освобождаем стек и выходим
	ret
	endp



readfile	proc; чтение из файла, дальнего вызова
	locals @@; принимает 2 параметра - буфер и имя файла
@@buffer	equ [bp+6]
@@filnam	equ [bp+8]
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	push di; 4 регистра для дос и вспомогательный
	mov ax,3d00h; открыть файл, режим чтение в ah, al
	mov dx,@@filnam; указательна буфер с именем файла заканчивающееся 0
	int 21h; в случае неудачи cf и код ошщибки(обычно просто ффайл не найден)
	jc @@ex
	mov bx,ax; в ax будет файловый дескриптор, ща будем читать
	mov cx,4095; сколько читаем, т.е. максимальное значение
	mov dx,@@buffer; читать будем в буфер
@@m1:	mov ah,3fh; чтение из файла
	int 21h
	jc @@er; на обработку ошибки er, ФАЙЛ НАДО ЗАКРЫТЬ
	or ax,ax; в ax кол-во прочитанных байт, сможет установить zf
	je @@m2; если все прочитали
	sub cx,ax; если прочитали всё, тоже на 2
	jcxz @@m2
	add dx,ax; иначе повторно запустить чтение, буфер частично заполниили, надо читать с того места, где закончилось предыдущее чтение
	jmp @@m1; выход по 1 из 2 условий: прочитали 4095 либо достигли конца файла
@@m2:	mov di,@@buffer; надо закрыть 0-байтом
	add di,4095
	sub di,cx; di туда, где заканчивается прочитанная инфа. 
	xor al,al
	stosb; заносим 0-байт
	mov ah,3eh; файл надо закрыть
	int 21h;файл закрыли
@@ex:	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp; освобождение регистров и выход выход
	ret
@@er:	mov ah,3eh
	int 21h
	stc
	jmp @@ex
	endp



writefile proc; запись в файл, 2 параметра, имя и что писать
	locals @@
@@filnam	equ [bp+8]
@@buffer	equ [bp+6]
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	push di; --//--
	mov ah,3ch; создать файл(он может не существовать), если его нет, если он есть - очистить(мб ошибка путь не найден или нет прав)
	xor cx,cx; атрибуты все 0
	mov dx,@@filnam; заносим адрес буфера где хранится имя файла закрытое 0 байтом
	int 21h; вызов функции дос
	jc @@ex; cf установили, разбирайтесь
	mov bx,ax; занесли файловый дескриптор в bx
	mov di,@@buffer; надо вычислить длину инфы которую надо занести в файл
	xor al,al
	mov cx,0ffffh; макс возможное значение(ЗАЧЕМ так много? -- можно сразу занести 4095, но могут быть трудности с вычислением кол-ва)
	repne scasb; сравниваем с 0
	neg cx; вычисление размера
	dec cx
	dec cx; в cx кол-во которое надо вывести не включая 0 байт
	jcxz @@ex1; ничего не выводим, на выход, закрыть
	cmp cx,4095; в cx всё равно 4095
	jbe @@m
	mov cx,4095
@@m:	mov ah,40h; функция
	mov dx,@@buffer;адрес
	int 21h;все готово к записи
	jc @@er; ошибка
@@ex1:	mov ah,3eh
	int 21h; закрыли перед выходом
@@ex:	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret
@@er:	mov ah,3eh; тоже закрываем
	int 21h
	stc
	jmp @@ex
	endp



menu	proc; поработаем с кадром стека, данных нет, они передаются извне, если они нужны то в стеке надо создавать локальные перменные
	locals @@; можно сделать кадр стека
@@ax		equ [bp-82]; будет храниться ax -- максимальное число пунктов меню
@@buffer	equ [bp-80]; номер альтернативы
@@items	equ	[bp+6]
	push bp
	mov bp,sp
	sub sp,80; делаем кадр стека -- в стеке остнется свободное пространство длиной 80 символов
	push ax; в кадре сохраняем значение ax
@@m:	push @@items;теперь вывести на экран альтернативы меню, передаём сам items!
	call output
	pop ax
	jc @@ex; если вывода не было сразу на выход
	push ds; будем работать с сегментом стека, сохраняем es, ds, чтобы потом их восстановить
	push es
	push ss;
	push ss;
	pop ds;
	pop es; и в ds и в es будет храниться сегмент стека
	mov ax,bp
	sub ax,80
	push ax
	call inputline
	pop ax
	pop es
	pop ds
	jc @@ex
	mov al,@@buffer
	cbw
	sub ax,'0'
	cmp ax,0
	jl @@m
	cmp ax,@@ax
	jg @@m
	clc
@@ex:	mov sp,bp
	pop bp
	ret
	endp



space	proc; принимает Si(ук-т на начало пос-ти),принимает di(на разделители), пропускает все разделители, после окончания работы si->начало слова или нульбайт
	locals @@
	push bp
	mov bp,sp
	push ax
	push cx
	push di
	xor al,al; обнуляем al, будем искать разделители, должны посчитать, сколько символов в масcиве разделителей
	mov cx,65535; занесли макс число
	repne scasb; будем повторять пока не совпадёт, scasb ищет символ на который ук-т di и потом выходит(зануляет сх)
	neg cx; в cx будет здесь 65533, по 0-байту выйдем, нег = 3, dec дает кол-во символов в строке разделителей
	dec cx
	push cx; сохраним в стеке
@@m1:	pop cx; в сх кол-во символов-разделителей
	pop di; 
	push di
	push cx
	lodsb; извлекаем очередной символ исх. строки и пытаемся его найти
	repne scasb; если нашли -выйдем раньше, если нет - пока сх не обнулится
	jcxz @@m2; если встретили не разделитель
	jmp @@m1; нашли очередной разделитель, повторим поиск разделителя
@@m2:	dec si 
	add sp,2; вытащили наш внутренний cx, можно сделать pop сх, но незачем делать pop вникуда
	pop di; восстановили состояние регистров
	pop cx
	pop ax
	pop bp
	ret
	endp; через si возвращает адрес очередного слова



words	proc; принимает si->нач слова, di->разделители пропускает слово, возвращает si, указывающий на первый символ после слова(разделитель или 0байт)
	locals @@
	push bp
	mov bp,sp
	push ax
	push cx
	push di
	xor al,al
	mov cx,65535
	repne scasb
	neg cx; длина тут на 1 больше тк ищем не только пробел-таб но и нул-байт, по нему тоже надо выходить
	push cx
@@m:	pop cx; извлекаем из стека длину массива
	pop di
	push di
	push cx
	lodsb; извлекаем очередной символ
	repne scasb
	jcxz @@m; если не нашли символ в массиве разделителей не нашли, то продолжаем
	dec si
	add sp,2; 1 лишний символ со стека
	pop di
	pop cx
	pop ax
	pop bp
	ret
	endp



compare proc; сравнение 2х слов, через стек 3 параметра: адрес 1 слова, 2го слова, длины в ax
	locals @@; обычное правило сравнения по алфавиту
	push bp
	mov bp,sp; сохраняем bp, по нему хранится сохраненное значение bp
	push bx; сохраняем те регистры что можем испортить
	push cx
	push si
	push di
	mov si,[bp+6]; 1й параметр, указатель на 1 слово
	mov di,[bp+8];...
	mov ax,[bp+10]; слово, в котором в старшем байте - длина 1, в младшем - 2го
	cmp ah,al; должны проделать цикл по длине меньшего слова
	jne @@ne
	mov cl, al
@@m2:	xor ch,ch; в cx длина коротко слова
	repe cmpsb; сравнивает байты, si и di, число повторений cx, повторять не больше чем cx раз но пока строки равны
	je @@eq; если совпали
	jne @@ne; не совпали
@@eq:	mov ax, 1
	jmp @@ex
@@ne:	xor ax, ax
	jmp @@ex
@@ex:	pop di; выход из процедуры
	pop si
	pop cx
	pop bx
	pop bp
	ret; 6
	endp



check	proc
	locals @@
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push si
	push di
	push dx
	lea di, lens
	mov cx, n
	dec cx
	jcxz @@ex; проверка на единственное слово
	dec n
	xor cx, cx
@@m1:	cmp cx, n; будет влож цикл
	jge @@ex
	mov dx, cx
@@m2:	inc dx
	cmp dx, n
	jg @@next
	mov si, di
	add si, dx
	cmp byte ptr [si], 0
	je @@m2
	mov al, [si]; внутренний
	mov si, di
	add si, cx
	mov ah, [si]; 1 - внешний, 2 - внутренний
	push ax; длины слов
	lea si, ptrs
	add si, dx
	add si, dx
	push [si]; ptrs[dx]; сначала 2(внутренний)
	lea si, ptrs
	add si, cx
	add si, cx
	push [si]; ptrs[bx]; потом 1(внешний)	
	call compare
	add sp, 6
	or ax, ax
	je @@m2; не совпали, итерируемся дальше
	mov si, di
	add si, dx
	mov byte ptr [si], 0; совпали, длину в 0
@@iter:	jmp @@m2
@@next:	inc cx
	jmp @@m1

@@ex:	pop dx
	pop di
	pop si; восстанавливаем все регистры
	pop cx
	pop bx
	pop ax
	pop bp
	ret
	endp	



algorithm	proc; -повторяющие слова
	locals @@
@@ibuf	equ [bp+6]
@@obuf	equ [bp+8]
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push si
	push di
	mov cx,0ffffh; надо вычислить размер буфера ввода: найти 0 байт и вычислить длину данных
	mov di,@@ibuf; начало буфера
	xor al,al
	repne scasb; ищем 0
	neg cx
	dec cx
	dec cx; длина без 0 байта в конце
	jcxz @@ex; если ничего не надо делать
	mov si, @@ibuf
	lea di, delim
	xor bx,bx; счётчик слов
@@m1:	call space; параметры через di и si
	cmp byte ptr [si],0
	je @@m2; конец строки => конец обработки
	shl bx,1
	mov ptrs[bx],si
	shr bx,1
	mov cx,si
	call words
	sub cx, si
	neg cx; длина слова
	mov lens[bx],cl
	inc bx
	cmp byte ptr [si],0
	jne @@m1
@@m2:	mov n, bx
	call check
	mov cx,bx
	xor bx,bx
	mov di,@@obuf
@@m3:	push cx; цикл будет вложенный
	cmp lens[bx], 0
	je @@m5
	or bx,bx
	je @@m4;
	mov al,' '; иначе в рез строку вставляем пробел
	stosb
@@m4:	shl bx,1; получить адрес начала очередного слова
	mov si,ptrs[bx]
	shr bx,1
	mov cl,lens[bx]; занесли кол-во символов в слове
	xor ch,ch;
	rep movsb; выполнится СХ раз, si и di сдвинутся на длину слова
@@m5:	inc bx; увеличили bx на 1
	pop cx;
	loop @@m3
@@ex:	mov ax, 13
	stosb
	mov ax, 10
	stosb
	xor al,al; надо закрыть строку нулевым байтом
	stosb; строка сформирована
	pop di
	pop si
	pop cx
	pop bx
	pop ax
	pop bp; восстанавливаем состояния всех регистров, всё
	ret
	endp
	end start
