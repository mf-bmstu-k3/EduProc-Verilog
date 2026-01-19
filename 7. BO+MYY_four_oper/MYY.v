//этот файл содержит описание МУУ в виде автомата МИЛИ, предназначенного для выполнения четырех операций:
//умножения а*b, результат формируется в 2n разрядной сетке
//сложения а+b, формируется признак результата = нулю, > нуля, < нуля, переполнение
//вычитание -а+b, формируется признак результата = нулю, > нуля, < нуля, переполнение 
//взятие операнда с противоположным знаком -а, формируется признак результата = нулю, > нуля, < нуля, переполнение
//sko формируется после получения результата 
module MYY (clk, set, cop, x, sno, sko, y);
	parameter N = 4; //параметр, задает разрядность операндов
	input clk; //тактовый
	input set; //сигнал начальной установки
	input [1:0] cop; //код операции: 00(а+b), 01(а*b), 10(-а+b), 11(-а)
	input wire [2:0] x; //логические условия,f3,f2,f1
	input sno; //сигнал начала операции
	output reg sko; //сигнал конца операции
	output reg [10:1] y; //управляющие сигналы для блока операций
	
	parameter s0=0,s1=1,s2=2, s3=3, s4=4;	//определяем состояния МУУ
	reg [3:0] state;					//регистр текущего состояния МУУ
   reg [3:0] next_state;			//регистр следующего состояния
	
	reg [(N-1):1] i;					//счетчик анализируемых разрядов множителя
	reg incr_i;							//разрешение инкремента i
	
	//этот процесс определяет текущее состояние МУУ
	always @ (posedge set or posedge clk)
	begin
		if (set) begin
			state = s0;
			end
		else begin 
			state = next_state;			
			end
	end 
	
//этот процесс определяет следующее состояние МУУ, управляющие сигналы для БО
	always @ (state or cop or sno or x or i)
	begin
		case (state)
			s0: begin 						//переходы из s0
				if (sno) begin 				//если есть сигнал начала операции
					next_state = s1; 
					y = 10'b0011000111;
				end
				else begin 						//иначе состояние не меняется
					next_state = s0; 
					y = 10'b0000000000;
				end				
			end
			s1: begin						//из s1 всегда переходим в s2
				next_state = s2;
				if  (cop == 2'b00) begin 		//если сложение
					y = 10'b0001101000;				//rr=RA+RB
				end
				else if (cop == 2'b10) begin	//если -а+b
					y = 10'b0001110000; 				//rr=-RA+RB
				end
				else if ((cop == 2'b11)|(x[1:0]==2'b01)) begin
					y = 10'b0101110000; 				//rr=rr -RA
				end
				else if (x[1:0]==2'b10) begin
					y = 10'b0101101000;				//rr=rr +RA 
				end
				else begin
					y = 10'b0101100000; 				//rr=rr+0 
				end		
			end
			s2: begin
				if (i == N-1) begin			//если умножение и обработали последний разряд множителя
					next_state = s0; 
					y = 10'b0000000000; 		//формируем сигнал конца операции
				end
				else if (cop==2'b01) begin	//если умножение
					next_state = s1; 
					y = 10'b0001000100;		//сдвиг rr, сдвиг RB
				end
				else if ((cop!=2'b01)&(x[2]==1'b0)) begin 	//если не умножение и нет отрицательного нуля
				   next_state = s4; 
					y = 10'b1000000000;  	//запись признака в RPR
				end
				else begin
					next_state = s3; 
					y = 10'b0011000000;  	//обнуляем rr
				end
			end
			s3: begin
				next_state = s4; 
				y = 10'b1000000000;  		//запись признака в RPR
			end
			s4: begin
				next_state = s0; 
				y = 10'b0000000000;  		//формируем сигнал конца операции sko
			end
			default: begin						//заглушка 
            y = 10'bxxxxxxxxxx;
            sko = 1'bx;
            incr_i = 1'bx;
            $display ("Reach undefined state");
			end
		endcase
	end
	
	//этот процесс формирует СКО и инкремент i
	always @* begin
		if (((state==2)&(i==N-1))|(state==4)) begin //формирование sko
			sko = 1; 
		end 
		else begin
			sko = 0;
		end
		if ((state == 2)&(cop==2'b01)&(i!=(N-1))) begin //инкремент i, если умножение и не все разряды проверили
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
