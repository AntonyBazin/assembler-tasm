	.model medium
public	items,fn,ibuf,obuf,msg,frm,qws,inp,bye,ptrs,lens,delim,n; делаем все данные паблик чтобы можно было к ним обращаться извне
	.data
items	db '1. Input from keyboard',13,10
	db '2. Read from file',13,10
	db '3. Output to screen',13,10
	db '4. Write to file',13,10
	db '5. Run the algorithm',13,10; 13, 10  - возврат каретки, перенос строки
	db '0. Exit to DOS',13,10
	db 'Input item number',13,10,0
fn	db 80 dup (?); буфер для ввода имени файла, inputline больше 79 в принципе никогда не сможет ввести, переполнения не будет
ibuf	db 4096 dup(?); вх и вых буферы
obuf	db 4096 dup(?); буферы всегда закрываются 0-байтом. 0- всегда граница.
ptrs	dw 2048 dup(?); указатели на слова
lens	db 2048 dup(?); длины слов
delim	db ' ',',',';','	',13,10,0; разделители
n dw ?
msg	db 'Error',13,10,0; сообщение о файловой ошибке
frm	db 'Incorrect format',13,10,0; сообщение неправильноого формата файла - если алгоритм говорит о некорректной работе
qws	db 'Input file name',13,10,0; запрос на ввод имени файла
inp	db 'Input text. To end input blank line',13,10,0; ввод текста с клавиатуры
bye	db 'Goodbye!',13,10,0; 
	end
