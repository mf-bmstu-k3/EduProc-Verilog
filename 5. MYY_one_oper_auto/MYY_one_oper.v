module MYY_one_oper (clk, set, x, sno, sko, y);
	input clk; //тактовый
	input set; // установка
	input [2:0] x; //логические условия,f3,f2,f1
	input sno; //сигнал начала операции
	output sko; //сигнал конца операции
	output [9:0] y; //управляющие сигналы для блока операций
	
		
	reg [1:0] i; //счетчик анализируемых разрядов множителя
	wire incr_i;

	//если пишем только сигналы, то обязательно в том же порядке, в котором они объявлены внутри модуля
	//SM1 #(.set, .clk, .x[2:0], .sno, .i[1:0], .y[10:1], .sko, .incr_i)
	//.куда(что) - можно задавать в любом порядке
	SM1 state_machine(.reset(set), .clock(clk), .x(x), .sno(sno), .i(i), .y(y), .sko(sko), .incr_i(incr_i));
		
	
	
	//этот процесс определяет поведение счетчика i
	always @ (posedge clk)
	begin
		if (sno) begin 
			i = 2'b01; //устанавливаем в начальное состояние
		end
		else if (incr_i==1'b1) begin //инкремент счетчик
			i = i+1'b1;
		end
	end
	
endmodule
