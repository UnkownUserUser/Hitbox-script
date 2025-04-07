-- Hello there, heres the hitbox script i guess
-- obfustacted by LuaObfuscator.com

--[[
 .____                  ________ ___.    _____                           __                
 |    |    __ _______   \_____  \\_ |___/ ____\_ __  ______ ____ _____ _/  |_  ___________ 
 |    |   |  |  \__  \   /   |   \| __ \   __\  |  \/  ___// ___\\__  \\   __\/  _ \_  __ \
 |    |___|  |  // __ \_/    |    \ \_\ \  | |  |  /\___ \\  \___ / __ \|  | (  <_> )  | \/
 |_______ \____/(____  /\_______  /___  /__| |____//____  >\___  >____  /__|  \____/|__|   
         \/          \/         \/    \/                \/     \/     \/                   
          \_Welcome to LuaObfuscator.com   (Alpha 0.10.9) ~  Much Love, Ferib 

]]--

local StrToNumber = tonumber;
local Byte = string.byte;
local Char = string.char;
local Sub = string.sub;
local Subg = string.gsub;
local Rep = string.rep;
local Concat = table.concat;
local Insert = table.insert;
local LDExp = math.ldexp;
local GetFEnv = getfenv or function()
	return _ENV;
end;
local Setmetatable = setmetatable;
local PCall = pcall;
local Select = select;
local Unpack = unpack or table.unpack;
local ToNumber = tonumber;
local function VMCall(ByteString, vmenv, ...)
	local DIP = 1;
	local repeatNext;
	ByteString = Subg(Sub(ByteString, 5), "..", function(byte)
		if (Byte(byte, 2) == 81) then
			repeatNext = StrToNumber(Sub(byte, 1, 1));
			return "";
		else
			local a = Char(StrToNumber(byte, 16));
			if repeatNext then
				local b = Rep(a, repeatNext);
				repeatNext = nil;
				return b;
			else
				return a;
			end
		end
	end);
	local function gBit(Bit, Start, End)
		if End then
			local Res = (Bit / (2 ^ (Start - 1))) % (2 ^ (((End - 1) - (Start - 1)) + 1));
			return Res - (Res % 1);
		else
			local Plc = 2 ^ (Start - 1);
			return (((Bit % (Plc + Plc)) >= Plc) and 1) or 0;
		end
	end
	local function gBits8()
		local a = Byte(ByteString, DIP, DIP);
		DIP = DIP + 1;
		return a;
	end
	local function gBits16()
		local a, b = Byte(ByteString, DIP, DIP + 2);
		DIP = DIP + 2;
		return (b * 256) + a;
	end
	local function gBits32()
		local a, b, c, d = Byte(ByteString, DIP, DIP + 3);
		DIP = DIP + 4;
		return (d * 16777216) + (c * 65536) + (b * 256) + a;
	end
	local function gFloat()
		local Left = gBits32();
		local Right = gBits32();
		local IsNormal = 1;
		local Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
		local Exponent = gBit(Right, 21, 31);
		local Sign = ((gBit(Right, 32) == 1) and -1) or 1;
		if (Exponent == 0) then
			if (Mantissa == 0) then
				return Sign * 0;
			else
				Exponent = 1;
				IsNormal = 0;
			end
		elseif (Exponent == 2047) then
			return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
		end
		return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
	end
	local function gString(Len)
		local Str;
		if not Len then
			Len = gBits32();
			if (Len == 0) then
				return "";
			end
		end
		Str = Sub(ByteString, DIP, (DIP + Len) - 1);
		DIP = DIP + Len;
		local FStr = {};
		for Idx = 1, #Str do
			FStr[Idx] = Char(Byte(Sub(Str, Idx, Idx)));
		end
		return Concat(FStr);
	end
	local gInt = gBits32;
	local function _R(...)
		return {...}, Select("#", ...);
	end
	local function Deserialize()
		local Instrs = {};
		local Functions = {};
		local Lines = {};
		local Chunk = {Instrs,Functions,nil,Lines};
		local ConstCount = gBits32();
		local Consts = {};
		for Idx = 1, ConstCount do
			local Type = gBits8();
			local Cons;
			if (Type == 1) then
				Cons = gBits8() ~= 0;
			elseif (Type == 2) then
				Cons = gFloat();
			elseif (Type == 3) then
				Cons = gString();
			end
			Consts[Idx] = Cons;
		end
		Chunk[3] = gBits8();
		for Idx = 1, gBits32() do
			local Descriptor = gBits8();
			if (gBit(Descriptor, 1, 1) == 0) then
				local Type = gBit(Descriptor, 2, 3);
				local Mask = gBit(Descriptor, 4, 6);
				local Inst = {gBits16(),gBits16(),nil,nil};
				if (Type == 0) then
					Inst[3] = gBits16();
					Inst[4] = gBits16();
				elseif (Type == 1) then
					Inst[3] = gBits32();
				elseif (Type == 2) then
					Inst[3] = gBits32() - (2 ^ 16);
				elseif (Type == 3) then
					Inst[3] = gBits32() - (2 ^ 16);
					Inst[4] = gBits16();
				end
				if (gBit(Mask, 1, 1) == 1) then
					Inst[2] = Consts[Inst[2]];
				end
				if (gBit(Mask, 2, 2) == 1) then
					Inst[3] = Consts[Inst[3]];
				end
				if (gBit(Mask, 3, 3) == 1) then
					Inst[4] = Consts[Inst[4]];
				end
				Instrs[Idx] = Inst;
			end
		end
		for Idx = 1, gBits32() do
			Functions[Idx - 1] = Deserialize();
		end
		return Chunk;
	end
	local function Wrap(Chunk, Upvalues, Env)
		local Instr = Chunk[1];
		local Proto = Chunk[2];
		local Params = Chunk[3];
		return function(...)
			local Instr = Instr;
			local Proto = Proto;
			local Params = Params;
			local _R = _R;
			local VIP = 1;
			local Top = -1;
			local Vararg = {};
			local Args = {...};
			local PCount = Select("#", ...) - 1;
			local Lupvals = {};
			local Stk = {};
			for Idx = 0, PCount do
				if (Idx >= Params) then
					Vararg[Idx - Params] = Args[Idx + 1];
				else
					Stk[Idx] = Args[Idx + 1];
				end
			end
			local Varargsz = (PCount - Params) + 1;
			local Inst;
			local Enum;
			while true do
				Inst = Instr[VIP];
				Enum = Inst[1];
				if (Enum <= 17) then
					if (Enum <= 8) then
						if (Enum <= 3) then
							if (Enum <= 1) then
								if (Enum == 0) then
									Stk[Inst[2]] = Stk[Inst[3]];
								else
									Stk[Inst[2]] = Inst[3];
								end
							elseif (Enum > 2) then
								local A = Inst[2];
								local B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
							else
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
							end
						elseif (Enum <= 5) then
							if (Enum == 4) then
								Stk[Inst[2]][Inst[3]] = Inst[4];
							else
								Stk[Inst[2]] = Env[Inst[3]];
							end
						elseif (Enum <= 6) then
							Stk[Inst[2]] = not Stk[Inst[3]];
						elseif (Enum > 7) then
							Stk[Inst[2]] = not Stk[Inst[3]];
						else
							local A = Inst[2];
							Stk[A] = Stk[A](Stk[A + 1]);
						end
					elseif (Enum <= 12) then
						if (Enum <= 10) then
							if (Enum == 9) then
								Stk[Inst[2]] = Upvalues[Inst[3]];
							else
								VIP = Inst[3];
							end
						elseif (Enum == 11) then
							local NewProto = Proto[Inst[3]];
							local NewUvals;
							local Indexes = {};
							NewUvals = Setmetatable({}, {__index=function(_, Key)
								local Val = Indexes[Key];
								return Val[1][Val[2]];
							end,__newindex=function(_, Key, Value)
								local Val = Indexes[Key];
								Val[1][Val[2]] = Value;
							end});
							for Idx = 1, Inst[4] do
								VIP = VIP + 1;
								local Mvm = Instr[VIP];
								if (Mvm[1] == 0) then
									Indexes[Idx - 1] = {Stk,Mvm[3]};
								else
									Indexes[Idx - 1] = {Upvalues,Mvm[3]};
								end
								Lupvals[#Lupvals + 1] = Indexes;
							end
							Stk[Inst[2]] = Wrap(NewProto, NewUvals, Env);
						else
							VIP = Inst[3];
						end
					elseif (Enum <= 14) then
						if (Enum == 13) then
							Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
						else
							do
								return;
							end
						end
					elseif (Enum <= 15) then
						Upvalues[Inst[3]] = Stk[Inst[2]];
					elseif (Enum > 16) then
						Stk[Inst[2]] = Inst[3] ~= 0;
					else
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
					end
				elseif (Enum <= 26) then
					if (Enum <= 21) then
						if (Enum <= 19) then
							if (Enum > 18) then
								Stk[Inst[2]] = Inst[3];
							else
								local A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
							end
						elseif (Enum > 20) then
							do
								return;
							end
						else
							Stk[Inst[2]] = Upvalues[Inst[3]];
						end
					elseif (Enum <= 23) then
						if (Enum > 22) then
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						else
							Upvalues[Inst[3]] = Stk[Inst[2]];
						end
					elseif (Enum <= 24) then
						if (Stk[Inst[2]] == Inst[4]) then
							VIP = VIP + 1;
						else
							VIP = Inst[3];
						end
					elseif (Enum == 25) then
						Stk[Inst[2]] = Env[Inst[3]];
					else
						local A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
					end
				elseif (Enum <= 30) then
					if (Enum <= 28) then
						if (Enum == 27) then
							local A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
						else
							Stk[Inst[2]] = Inst[3] ~= 0;
						end
					elseif (Enum == 29) then
						local A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
					else
						local A = Inst[2];
						Stk[A](Unpack(Stk, A + 1, Inst[3]));
					end
				elseif (Enum <= 32) then
					if (Enum == 31) then
						local A = Inst[2];
						local B = Stk[Inst[3]];
						Stk[A + 1] = B;
						Stk[A] = B[Inst[4]];
					else
						Stk[Inst[2]][Inst[3]] = Inst[4];
					end
				elseif (Enum <= 33) then
					local NewProto = Proto[Inst[3]];
					local NewUvals;
					local Indexes = {};
					NewUvals = Setmetatable({}, {__index=function(_, Key)
						local Val = Indexes[Key];
						return Val[1][Val[2]];
					end,__newindex=function(_, Key, Value)
						local Val = Indexes[Key];
						Val[1][Val[2]] = Value;
					end});
					for Idx = 1, Inst[4] do
						VIP = VIP + 1;
						local Mvm = Instr[VIP];
						if (Mvm[1] == 0) then
							Indexes[Idx - 1] = {Stk,Mvm[3]};
						else
							Indexes[Idx - 1] = {Upvalues,Mvm[3]};
						end
						Lupvals[#Lupvals + 1] = Indexes;
					end
					Stk[Inst[2]] = Wrap(NewProto, NewUvals, Env);
				elseif (Enum == 34) then
					if (Stk[Inst[2]] == Inst[4]) then
						VIP = VIP + 1;
					else
						VIP = Inst[3];
					end
				else
					Stk[Inst[2]] = Stk[Inst[3]];
				end
				VIP = VIP + 1;
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
return VMCall("LOL!2C3Q0003083Q00496E7374616E63652Q033Q006E657703093Q005363722Q656E477569030A3Q005465787442752Q746F6E03083Q005549436F726E657203043Q0067616D6503073Q00506C6179657273030B3Q004C6F63616C506C6179657203093Q00436861726163746572030E3Q0046696E6446697273744368696C6403063Q00486974626F7803093Q00776F726B7370616365030C3Q0057616974466F724368696C6403083Q00462Q6F7462612Q6C03043Q004E616D6503093Q00486974626F7847554903063Q00506172656E7403093Q00506C61796572477569030E3Q005A496E6465784265686176696F7203043Q00456E756D03073Q005369626C696E6703123Q00546F2Q676C65486974626F7842752Q746F6E03103Q004261636B67726F756E64436F6C6F723303063Q00436F6C6F723303073Q0066726F6D524742025Q00E06F40030C3Q00426F72646572436F6C6F7233028Q00030F3Q00426F7264657253697A65506978656C03083Q00506F736974696F6E03053Q005544696D32027E8969C0CF21C93F03043Q0053697A65025Q00C05240026Q003B4003043Q00466F6E74030A3Q00536F7572636553616E7303043Q0054657874030B3Q00486974626F783A204F2Q46030A3Q0054657874436F6C6F723303083Q005465787453697A65026Q002C4003113Q004D6F75736542752Q746F6E31436C69636B03073Q00436F2Q6E656374005F3Q0012193Q00013Q0020175Q0002001213000100034Q00073Q00020002001219000100013Q002017000100010002001213000200044Q0007000100020002001219000200013Q002017000200020002001213000300054Q0007000200020002001219000300063Q00201700030003000700201700030003000800201700040003000900201F00050004000A0012130007000B4Q001A000500070002001219000600063Q00201700060006000C00201F00060006000D0012130008000E4Q001A00060008000200201F00070006000D0012130009000B4Q001A0007000900022Q001C00085Q0030203Q000F0010001219000900063Q0020170009000900070020170009000900080020170009000900120010023Q00110009001219000900143Q0020170009000900130020170009000900150010023Q001300090030200001000F0016001002000100113Q001219000900183Q002017000900090019001213000A001A3Q001213000B001A3Q001213000C001A4Q001A0009000C0002001002000100170009001219000900183Q002017000900090019001213000A001C3Q001213000B001C3Q001213000C001C4Q001A0009000C00020010020001001B00090030200001001D001C0012190009001F3Q002017000900090002001213000A001C3Q001213000B001C3Q001213000C00203Q001213000D001C4Q001A0009000D00020010020001001E00090012190009001F3Q002017000900090002001213000A001C3Q001213000B00223Q001213000C001C3Q001213000D00234Q001A0009000D0002001002000100210009001219000900143Q002017000900090024002017000900090025001002000100240009003020000100260027001219000900183Q002017000900090019001213000A001C3Q001213000B001C3Q001213000C001C4Q001A0009000C000200100200010028000900302000010029002A00100200020011000100060B00093Q000100046Q00088Q00018Q00078Q00053Q002017000A0001002B00201F000A000A002C2Q0023000C00094Q001B000A000C00012Q00153Q00013Q00013Q00133Q002Q0103043Q0054657874030A3Q00486974626F783A204F4E03103Q004261636B67726F756E64436F6C6F723303063Q00436F6C6F723303073Q0066726F6D524742028Q00025Q00E06F4003043Q0053697A6503073Q00566563746F72332Q033Q006E6577026Q003440030C3Q005472616E73706172656E6379026Q00E03F03053Q00436F6C6F72030B3Q00486974626F783A204F2Q46026Q002440026Q00F03F025Q00A0644000644Q00098Q00068Q000F8Q00097Q0026223Q00350001000100040C3Q003500012Q00093Q00013Q0030203Q000200032Q00093Q00013Q001219000100053Q002017000100010006001213000200073Q001213000300083Q001213000400074Q001A0001000400020010023Q000400012Q00093Q00023Q0012190001000A3Q00201700010001000B0012130002000C3Q0012130003000C3Q0012130004000C4Q001A0001000400020010023Q000900012Q00093Q00023Q0030203Q000D000E2Q00093Q00023Q001219000100053Q002017000100010006001213000200083Q001213000300083Q001213000400084Q001A0001000400020010023Q000F00012Q00093Q00033Q0012190001000A3Q00201700010001000B0012130002000C3Q0012130003000C3Q0012130004000C4Q001A0001000400020010023Q000900012Q00093Q00033Q0030203Q000D000E2Q00093Q00033Q001219000100053Q002017000100010006001213000200083Q001213000300083Q001213000400084Q001A0001000400020010023Q000F000100040C3Q006300012Q00093Q00013Q0030203Q000200102Q00093Q00013Q001219000100053Q002017000100010006001213000200083Q001213000300083Q001213000400084Q001A0001000400020010023Q000400012Q00093Q00023Q0012190001000A3Q00201700010001000B001213000200113Q001213000300113Q001213000400114Q001A0001000400020010023Q000900012Q00093Q00023Q0030203Q000D00122Q00093Q00023Q001219000100053Q002017000100010006001213000200133Q001213000300133Q001213000400134Q001A0001000400020010023Q000F00012Q00093Q00033Q0012190001000A3Q00201700010001000B001213000200113Q001213000300113Q001213000400114Q001A0001000400020010023Q000900012Q00093Q00033Q0030203Q000D00122Q00093Q00033Q001219000100053Q002017000100010006001213000200133Q001213000300133Q001213000400134Q001A0001000400020010023Q000F00012Q00153Q00017Q00", GetFEnv(), ...);
