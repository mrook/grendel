program gasm;
uses gasmdef, strip, Classes, SysUtils, dtypes;

type
	Asm_Statement = class
		lineNum : integer;
	end;

	Asm_Line = class(Asm_Statement)
		opcode : integer;
		attr : string;

		code : array of char;
    displ : integer;
	end;
	
	Asm_Jump = class(Asm_Statement)
		opcode : integer;
		lbl : string;

    addr : integer;
	end;

	Asm_Label = class(Asm_Statement)
		lbl : string;
	  addr : integer;
	end;
	
	Symbol = class
	  id : string;
	  lbl : string;
	  addr : integer;
	end;

var 
  lineNum, codeSize, dataSize : integer;
  input : textfile;
	output : file;
  statements, symbols : GDLinkedList;
  errors : boolean;

procedure asmError(lineNum : integer; msg : string);
begin
  writeln('error (line ', lineNum, '): ', msg);

  errors := true;
end;

function getLine : string;
var
	look : string;
begin
  inc(lineNum);

  readln(input, look);

  Result := look;
end;

function readLine : Asm_Statement;
var
   statement, keyword, rhs : string;
   a, opcode : integer;
   sym : Symbol;
begin
  Result := nil;
  statement := getLine();
	opcode := -1;

  if (length(statement) = 0) then
    exit;

	keyword := left(statement, ' ');
  rhs := right(statement, ' ');

  if (keyword = '$DATA') then
    begin
		dataSize := StrToIntDef(rhs, 0);
		exit;
		end;

  if (keyword = '$SYMBOL') then
    begin
    sym := Symbol.Create;
    sym.id := left(rhs, ' ');
    sym.lbl := right(rhs, ' ');
    symbols.insertLast(sym);
		exit;
		end;

  if (keyword[length(keyword)] = ':') then
    begin
    Result := Asm_Label.Create;
		Asm_Label(Result).lbl := left(keyword, ':');
		Asm_Label(Result).lineNum := lineNum;

		exit;
    end;

  for a := 1 to opcodeNum do
    begin
    if (opcodes[a].keyword = keyword) then
      begin
      opcode := opcodes[a].opcode;
			break;
			end;
    end;

	if (opcode = -1) then
    begin
    asmError(lineNum, 'illegal opcode ' + keyword); 
    exit;
    end;

  case opcode of
		_JMP, _JZ, _JNZ,
    _CALL						: begin
											Result := Asm_Jump.Create;
											Asm_Jump(Result).lbl := rhs;
											Asm_Jump(Result).opcode := opcode;
											Asm_Jump(Result).lineNum := lineNum;
											end;
		else							begin
											Result := Asm_Line.Create;
											Asm_Line(Result).attr := rhs;
											Asm_Line(Result).opcode := opcode;
											Asm_Line(Result).lineNum := lineNum;
											end;
  end;
end;

procedure optimize;
var
	node, node_next : GListNode;
	stat : Asm_Statement;
	line : Asm_Line;
begin
  node := statements.head;

  while (node <> nil) do
    begin
    node_next := node.next;
    stat := node.element;

		if (not (stat is Asm_Line)) then
      begin
      node := node_next;
			continue;
      end;

		line := Asm_Line(stat);

		node := node_next;
		end;
end;

procedure genCode;
var
	b, displ : integer;
  f : single;
  stat : Asm_Statement;
  line : Asm_Line;
  jump : Asm_Jump;
  lbl : Asm_Label;
	node, node_in : GListNode;
	sym : Symbol;
begin
  displ := 0;

  node := statements.head;

  while (node <> nil) do
    begin
    stat := node.element;

    if (stat is Asm_Line) then
      begin
      line := Asm_Line(stat);

			case line.opcode of
				_PUSHI : 	begin
									line.displ := 5;
									setLength(line.code, 4);
									b := StrToInt(line.attr);
									move(b, line.code[0], 4);
									end;
				_PUSHF : 	begin
									line.displ := 5;
									setLength(line.code, 4);
									val(line.attr, f, b);
									move(f, line.code[0], 4);
									end;
				_PUSHS : 	begin
									line.displ := length(line.attr) + 2;
									setLength(line.code, length(line.attr) + 1);

									for b := 1 to length(line.attr) do
                    line.code[b - 1] := line.attr[b];

									line.code[length(line.attr)] := #0;
									end; 
 		 _PUSHDISP :  begin
									b := StrToInt(line.attr);
									line.displ := 5;

									setLength(line.code, 4);
									move(b, line.code[0], 4);
									end;
 		  _POPDISP :  begin
									b := StrToInt(line.attr);
									line.displ := 5;

									setLength(line.code, 4);
									move(b, line.code[0], 4);
									end;
 			  _PUSHR :  begin
									b := StrToInt(right(line.attr, 'R'));
									line.displ := 5;

									setLength(line.code, 4);
									move(b, line.code[0], 4);
									end;
 			   _POPR :  begin
									b := StrToInt(right(line.attr, 'R'));
									line.displ := 5;

									setLength(line.code, 4);
									move(b, line.code[0], 4);
									end;
 			   _MTSD :  begin
									b := StrToInt(right(line.attr, 'R'));
									line.displ := 5;

									setLength(line.code, 4);
									move(b, line.code[0], 4);
									end;
				_CALLE : 	begin
									line.displ := length(line.attr) + 2;
									setLength(line.code, length(line.attr) + 1);

									for b := 1 to length(line.attr) do
                    line.code[b - 1] := line.attr[b];

									line.code[length(line.attr)] := #0;
									end; 
				_ADDSP : 	begin
									line.displ := 5;
									setLength(line.code, 4);
									b := StrToInt(line.attr);
									move(b, line.code[0], 4);
									end;
				_SUBSP : 	begin
									line.displ := 5;
									setLength(line.code, 4);
									b := StrToInt(line.attr);
									move(b, line.code[0], 4);
									end;

				else
            begin
						setlength(line.code, 0);
						line.displ := 1;
						end;
			end;

	    inc(displ, line.displ);
			end
    else
    if (stat is Asm_Label) then
      begin
      lbl := Asm_Label(stat);

      lbl.addr := displ;
      end
		else
		if (stat is Asm_Jump) then
			inc(displ, 5);
    
		node := node.next;
		end;

  node := statements.head;

  while (node <> nil) do
    begin
    stat := node.element;

    if (stat is Asm_Jump) then
      begin
      jump := Asm_Jump(stat);
      jump.addr := -1;

			node_in := statements.head;
			while (node_in <> nil) do
        begin
        if (not (Asm_Statement(node_in.element) is Asm_Label)) then
					begin
					node_in := node_in.next;
          continue;
					end;

        lbl := Asm_Label(node_in.element);

        if (lbl.lbl = jump.lbl) then
          begin
          jump.addr := lbl.addr;
          break;
          end;
          
				node_in := node_in.next;
        end;

      if (jump.addr = -1) then
        asmError(jump.lineNum, 'undefined label ' + jump.lbl);
      end;

		node := node.next;
    end;
 
  codeSize := displ;
  
  node := symbols.head;
  
  while (node <> nil) do
    begin
    sym := node.element;
    
		node_in := statements.head;
		while (node_in <> nil) do
      begin
      if (not (Asm_Statement(node_in.element) is Asm_Label)) then
				begin
				node_in := node_in.next;
        continue;
				end;

      lbl := Asm_Label(node_in.element);

      if (lbl.lbl = sym.lbl) then
        begin
        sym.addr := lbl.addr;
        break;
        end;

			node_in := node_in.next;
      end;

    node := node.next;
    end;
end;

procedure writeCode;
var
  stat : Asm_Statement;
  sym : Symbol;
  line : Asm_Line;
  jump : Asm_Jump;
  node : GListNode;
  t : byte;
begin
	blockwrite(output, codeSize, 4);
	blockwrite(output, dataSize, 4);

  node := statements.head;
  while (node <> nil) do
    begin
    stat := node.element;

    if (stat is Asm_Line) then
      begin
      line := Asm_Line(stat);

			blockwrite(output, line.opcode, 1);
			blockwrite(output, line.code[0], length(line.code));
			end
    else
    if (stat is Asm_Jump) then
      begin
			jump := Asm_Jump(stat);

			blockwrite(output, jump.opcode, 1);
			blockwrite(output, jump.addr, 4);
			end;

		node := node.next;
		end;
		
	node := symbols.head;
	while (node <> nil) do
	  begin
	  sym := node.element;

    t := length(sym.id);
    blockwrite(output, t, 1);
    blockwrite(output, sym.id[1], length(sym.id));
  	blockwrite(output, sym.addr, 4);

		node := node.next;
	  end;
end;

var
	root : Asm_Statement;
  ifname : string;
  ofname : string;

begin
  writeln('GASM - GMC ''Elise'' v0.3'#13#10);
  errors := false;

  if (paramcount < 1) then
    begin
    writeln('gasm <input file>');
    exit;
    end;

  ifname := paramstr(1);
  ofname := ChangeFileExt(ifname, '.cod');

  assignfile(input, ifname);
  {$I-}
  reset(input);
  {$I+}

  if (IOResult <> 0) then
    begin
    writeln('Could not open ', ifname);
    exit;
    end;

  statements := GDLinkedList.Create;
  symbols := GDLinkedList.Create;

  while (not eof(input)) do 
    begin
		root := readLine();

    if (root <> nil) then
      statements.insertLast(root);
    end;

  closefile(input);

  if (errors) then
    exit;

	optimize();

  if (errors) then
    exit;

  genCode();

  if (errors) then
    exit;

  assignfile(output, ofname);
  {$I-}
  rewrite(output, 1);
  {$I+}

  if (IOResult <> 0) then
    begin
    writeln('Could not open ', ofname);
    exit;
    end;

  writeCode();

	writeln('Saved ', codeSize, ' byte(s) of code, ', dataSize, ' element(s) data.');

  closefile(output);
end.
