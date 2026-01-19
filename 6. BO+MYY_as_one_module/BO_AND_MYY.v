//этот файл содержит описание операционного устройства для выполнения умножения и сложения
//он представляет собой verilog описание схемного проекта contr_unit_BO, представленного на верхнем уровне как МУУ(файл control unit) + БО (файл BO)
//Операнды n разрядные


module BO_AND_MYY (a, b, clk, set, cop, sno, rr, priznak, sko);
	parameter N =  4;
	
	input clk;							//тактовый сигнал
	input set;							//сигнал начальной установки
	input cop;							//код операции 1-умножение,0 - сложение
	input sno;							//сигнал начала операции
	input wire [(N-1):0] a; 		//первый операнд
	input wire [(N-1):0] b; 		//второй операнд
	output reg [(2*N-1):0] rr; 	//результат
	output reg [1:0] priznak; 		//признак результата
	output reg sko;					//сигнал конца операции

	reg [3:0] state;					//регистр текущего состояния МУУ
   reg [3:0] next_state;			//регистр следующего состояния
   parameter s0=0,s1=1,s2=2, s3=3, s4=4;	//определяем состояния МУУ

	reg [(N-1):0] i;					//счетчик анализируемых разрядов множителя
	reg incr_i;							//разрешение инкремента i
	
	reg [(N-1):0] RA;					//для запоминания а и в
	reg [(N-1):0] RB;
	
	reg [(2*N-1):0] d;				//выход КС1
	reg [(2*N-1):0] q;				//выход КС2
	reg [(2*N-1):0] s;				//выход сумматора
	reg [1:0] pr; 						//выход КС3
	reg [2:0] x;						//логические условия
	reg [10:1] y;						//управляющие сигналы для блока операций

	reg [(2*N):0] zero = 0; 		//0 (вспомогательный)

	
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
	always @ (state or cop or sno or x or i)
	begin
		case (state)
			s0: begin
				if (sno) begin 				//если есть сигнал начала операции
					next_state = s1; 
					y = 10'b0011000111;
				end
				else begin						//иначе состояние не меняется
					next_state = s0; 
					y = 10'b0000000000;
				end
			end
			s1: begin
				next_state = s2; 				//из s1 всегда переходим в s2
				if (!cop) begin			//если сложение
						y = 10'b0001101000;	//rr=RA+RB
				end
				else if ((cop)&(x[1:0] == 2'b10)) begin
					y = 10'b0101101000; 		//rr=rr +RA  	
				end
				else if ((cop)&(x[1:0] == 2'b01)) begin
					y = 10'b0101110000;		//rr=rr -RA
				end
				else begin
					y = 10'b0101100000;		//rr=rr+0 
				end
			end
			s2: begin
				if (i == (N-1)) begin		//если последний разряд
					next_state = s0; 
					y = 10'b0000000000; 		//формируем сигнал конца операции
				end
				else if (cop) begin			//если умножение
					next_state = s1; 
					y = 10'b0001000100;  	//сдвиг rr, сдвиг RB
				end
				else if (~x[2]) begin 		//если сложение и нет отрицательного нуля
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
				y = 10'b0000000000;			//формируем сигнал конца операции
			end
			default: begin
            y = 10'bxxxxxxxxxx;
            sko = 1'bx;
            incr_i = 1'bx;
            $display ("Reach undefined state");
           end
		endcase
	end
	
	//формирование , инкремент i
	always @* begin
		if (((state==s2)&&((i==(N-1))))||(state==s4)) begin 
			sko = 1; 
		end
		else begin
			sko = 0;
		end
		
		if (((state == s2)&&(i!=(N-1)))||(state==s4)) begin
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
	
	
	//этот процесс описывает логику работы регистра RA 
	always @(posedge clk) begin		//по положительному фронту clk
		if (y[1]) begin 					//если есть разрешение
			RA = a;							//выполняется прием первого операнда
		end
	end
	
	//этот процесс описывает логику работы регистра RB 
	always @(posedge clk) begin		//по положительному фронту clk
		if (y[3]) begin 					//если есть разрешение тактирования
			if (y[2]) begin				//если разрешена загрузка
				RB = b;  					//прием второго операнда
			end
			else begin
				RB = {RB[N-1], RB[(N-3):0], 1'b0}; //иначе сдвиг влево RB с сохранением знака
			end
		end
	end
	
	//этот процесс описывает КС1
	//d - выход КС1
	always @* begin
		case (y[5:4])
			2'b01: begin 										//если y4=1
				if (RA[N-1]) begin							//если число отрицательное
					d[(2*N-1):N] = ~zero[(2*N-1):N];		//старшим разрядам присваивается 1
				end
				else if (!RA[N-1]) begin					//иначе если число положительное
					d[(2*N-1):N] = zero[(2*N-1):N];		//старшим разрядам присваивается 0
				end
				d[(N-1):0] = RA;								//передаем на суммирование +А
			end
			2'b10: begin
				if (RA[N-1]) begin							//если число отрицательное
					d[(2*N-1):N] = zero[(2*N-1):N];		//старшим разрядам присваивается0
				end
				else if (!RA[N-1]) begin					//иначе если число положительное
					d[(2*N-1):N] = ~zero[(2*N-1):N];		//старшим разрядам присваивается 1
				end
				d[(N-1):0] = ~RA;								//передаем на суммирование -А
			end
			default: begin
				d[(2*N-1):0] = 0;								//ноль в остальных случаях
			end
		endcase
	end

	
	//этот процесс описывает КС2
	//q - выход КС2
	always @* begin
		if(y[9]) begin											//когда умножение
				q[(2*N-1):0] = rr[(2*N-1):0];
		end
		else begin												//когда сложение
			if (RB[N-1]) begin							
				q[(2*N-1):N] = ~zero[(2*N-1):N];		
			end
			else if (!RB[N-1]) begin					
				q[(2*N-1):N] = zero[(2*N-1):N];		
			end
			q[(N-1):0] = RB[(N-1):0];		
		end
	end

		
	//этот процесс описывает работу сумматора в обратном коде
	//к его входам подключены выходы КС1 и КС2
	reg [(2*N):0] sym = 0; 	//для вычисления суммы
	
	always @* begin
		sym = d + q;			//сложение
		sym[(2*N-1):0] = sym + sym[2*N];
		s <= sym[(2*N-1):0];
	end

	//этот процесс описывает работу регистра результата
	always @(posedge clk) begin
		if (y[8]) begin
			rr = zero;   				//очистка rr
		end
		else if (y[7]) begin 		//если есть разрешение тактирования
			if (y[6]) begin 
				rr = s;					//загрузка rr
			end
			else begin
				rr = {rr[(2*N-2):0], rr[2*N-1]}; //циклический сдвиг влево rr
			end
		end
	end			
			
	//этот процесс описывает КС3, которая формирует признак результата
	//q - выход КС2
	always @* begin
		pr[0] = rr[4]|(rr[3]);
		pr[1] = {((~rr[4]|(~rr[3]))&(rr[4]|rr[3]|rr[2]|rr[1]|rr[0]))};
	end
	
	//этот процесс описывает работу регистра признака
	always @(posedge clk) begin
		if (y[10]) begin 
			priznak<=pr; 							//запоминаем признак результата
		end
	end

	//ниже приводится описание логических условий
	always @* begin
		x[0]= RB[N-1];   							//знак множителя
		x[1]= RB[N-2];								//анализируемый разряд множителя
		if (rr[N:0]==(~zero[N:0])) begin		//отрицательный ноль
			x[2]= 1'b1;
		end
		else begin
			x[2]= 1'b0;			
		end
	end
endmodule
