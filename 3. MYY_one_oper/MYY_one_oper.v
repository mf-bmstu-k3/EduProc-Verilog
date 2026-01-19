module MYY_one_oper (clk, set, x, sno, sko, y);
	parameter N = 4;
	input clk; //тактовый
	input set; // установка
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
		if (set) begin
			state = 0;
			end
		else begin 
			state = next_state;			
			end
	end 
	 
	 //этот процесс определяет следующее состояние МУУ, управляющие сигналы для БО
	 always @ (state or sno or x or i)
	 begin
		if (state == 0) begin //переходы из s0
			if (sno) begin //если есть сигнал начала операции
				next_state = 1; 
				y = 10'b0111000111;
			end
			else begin //иначе состояние не меняется
				next_state = 0; 
				y = 10'b0000000000;
			end
		end
		else if (state == 1) begin //из s1 всегда переходим в s2
			next_state = 2; 
			if (x[1:0] == 2'b10) begin
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
			if (i == (N-1)) begin 
				next_state = 0; 
				y = 10'b0000000000; //формируем сигнал конца операции
			end
			else begin
				next_state = 1; 
				y = 10'b0001000100; //иначе сдвиг rr, сдвиг RB
			end				
		end
	end
	
	//формирование sko, инкремент i
	always @* begin
	
		if ((state==2)&((i==N-1))) begin 
			sko = 1; 
		end
		else begin
			sko = 0;
		end
		
		if ((state == 2)&(i!=(N-1))) begin
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
		else if (incr_i==1) begin //инкремент счетчик
			i = i+1;
		end
	end
	
endmodule
