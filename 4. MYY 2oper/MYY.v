//этот файл содержит описание МУУ в виде автомата МИЛИ, предназначенного для выполнения умножения и сложения
//sko формируется после получения произведения 
module MYY (clk, set, cop, x, sno, sko, y);
	parameter N = 4; //параметр, задает разрядность операндов
	input clk; //тактовый
	input set; //сигнал начальной установки
	input cop; //код операции операция 1-умножение 0-сложение
	input wire [2:0] x; //логические условия,f3,f2,f1
	input sno; //сигнал начала операции
	output reg sko; //сигнал конца операции
	output reg [10:1] y; //управляющие сигналы для блока операций
	
		
	integer i = 1; //счетчик анализируемых разрядов множителя
	integer incr_i = 0;

	integer state = 0; // текущее состояние
	integer next_state; //следующее состояние, 

	//этот процесс определяет текущее состояние МУУ
	always @ (posedge set or posedge clk)
	begin
		if (set) begin //если разрешена установка
			state = 0; //начальное состояние 0
			end
		else begin //иначе следующее состояние
			state = next_state;			
			end
	end 
	 
	 //этот процесс определяет следующее состояние МУУ и управляющие сигналы для БО
	 always @ (state or cop or sno or x or i)
	 begin
		if (state == 0) begin //если есть сигнал начала операции
			if (sno) begin
				next_state = 1; 
				y = 10'b0011000111;
			end
			else begin //иначе состояние не меняется
				next_state = 0; 
				y = 10'b0000000000;
			end
		end
		else if (state == 1) begin //из s1 всегда переходим в s2
			next_state = 2; 
			if  (cop == 0) begin //если сложение
				y = 10'b0001101000;//RR=RA+RB
			end
			else if (x[1:0] == 2'b10) begin
				y = 10'b0101101000; //RR=RR +RA  	
			end
			else if (x[1:0] == 2'b01) begin 
				y = 10'b0101110000; //RR=RR -RA
			end
			else begin
				y = 10'b0101100000; //RR=RR+0 
			end		
		end
		else if (state == 2) begin 
			if (i == (N-1)) begin //если это последний разряд
				next_state = 0; 
				y = 10'b0000000000; //формируем СКО
			end
			else if (cop) begin //иначе если умножение
				next_state = 1; 
				y = 10'b0001000100; //сдвиг RR, сдвиг RB
			end
			else if ((cop == 1'b0) & (x[2] == 1'b0)) begin //иначе если сложение и нет отрицательного нуля
				next_state = 4; 
				y = 10'b1000000000; //запись признака в RPR
			end
			else begin //иначе если сложение и есть отрицательный ноль
				next_state = 3; 
				y = 10'b0011000000; //обнуляем RR
			end				
		end
		else if (state == 3) begin 
			next_state = 4; 
			y = 10'b1000000000; //иначе запись признака в RPR
		end 
		else if (state == 4) begin 
			next_state = 0; 
			y = 10'b0000000000; //формируем СКО
		end 
	end
	
	
	always @* begin
		if (((state==2)&(i==N-1))|(state==4)) begin //формирование sko
			sko = 1; 
		end
		else begin
			sko = 0;
		end
		if ((state == 2)&(i!=N)) begin //инкремент i, когда умножение и не последний разряд множителя
			incr_i = 1;
		end
		else begin 
			incr_i = 0;
		end
	end

	//этот процесс определяет поведение счетчика i
	always @ (posedge clk)
	begin
		if (sno) begin 
			i = 1; //устанавливаем в начальное состояние
		end
		else if (incr_i) begin //инкремент счетчика
			i = i+1;
		end
	end
	
endmodule
