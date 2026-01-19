//кс4 - признак отрицательного нуля
module ks4 (rr, ks4_out);									//объявление модуля и его входов/выходов
	parameter N = 4;											//параметр для изменения размера шины данных
	input wire [N:0] rr;   									//вход данных с регистр результата
	output reg ks4_out;   									//выход схемы
	
	wire [N:0] zero = 0;										//0
	
	always @* begin											//блок описания поведения комбинационной схемы
		if (rr[N:0] + 1'b1 == zero[N:0]) begin			//если рр+1 = 0
			ks4_out = 1'b1;									//признак = 1
		end			
		else begin												//иначе признак = 0
			ks4_out = 1'b0;
		end
	end

endmodule 