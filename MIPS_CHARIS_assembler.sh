#!/bin/bash +x

#        Date: 25-05-2020
#      Author: Konstantinidis Konstantinos <electronic_arts@msn.com>
# Description: Given a set of CHARIS instructions (TUC/ECE 2020 LAB) in assembly, it produces the binary machine code.

cd $(dirname ${0}) # makes sure we run it from its path

#source ~/SKYNET_scripts/0.4.DLL/shell/ # Contains frequently used source code

cnvDec2Bin(){
	local dec=$1 ; local bits=$2		#the decimal to convert and the number of bits
	[ -z "$dec" ] && dec=0
	local bin=$(printf "%0.${bits}d\n" $(echo "ibase=10;obase=2;$(((2**(bits))+$dec))" | bc) )
	bin=$(echo $bin | grep -oE "[[:digit:]]{$bits}$")			# HERE 
	echo $bin
}
cnvHex2Bin(){
	local dec=$1 ; local bits=$2		#the decimal to convert and the number of bits
	printf "%0.${bits}d\n" $(echo "ibase=16;obase=2;$dec" | bc)
}

getINSTRidx(){
	local instr=${1}
	for((i=0;i<${#INSTRs_OPC[@]};i++));
	do
#		echo "${INSTRs_OPC[$i]} ${INSTRs_TYPE[$i]} ${INSTRs_ASBL[$i]} ${INSTRs_FUNC[$i]}"
		[ $instr = ${INSTRs_ASBL[$i]} ] && echo $i && return 0
	done
	echo "$1 invalid CHARIS instruction"
}

commonSyntx(){
	INSTRS_NAMES="(ADD|SUB|AND|OR|NOT|NAND|NOR|SRA|SRL|SLL|ROL|ROR|LI|LUI|ADDI|NANDI|ORI|B|BEQ|BNE|LB|SB|LW|SW)"
	Comma_syntax='[[:space:]]*,[[:space:]]*'			# "R0, R1", "R0 ,R1", "R0 , R1"
	Reg_syntax='R([[:digit:]]|[12][[:digit:]]|3[01])'		# R0-R31
	HEX_syntax='(0X)?[[:digit:]ABCDEF]{1,4}'			# 0XFFFF, FFFF, f, 000f
	MEMref_syntax="[+-]?[[:digit:]]{1,4}\($Reg_syntax\)"		# -4(R0), 4(R0), 0X0F
}
chkRsyntx(){
	local instr="$1"

	commonSyntx		# Register & Hex immediate input syntax
	local R2R_Inst="(ADD|SUB|AND|OR|NOT|NAND|NOR)"							# Register-to-Register Instructions
	local Sh_Inst="(SRA|SRL|SLL|ROL|ROR)"								# Shift Instructions
	local R2R_syntax="${R2R_Inst}[[:space:]]+(${Reg_syntax}${Comma_syntax}){1,2}${Reg_syntax}"
	local Shift_syntax="${Sh_Inst}[[:space:]]+${Reg_syntax}"
	echo "$instr" | grep -qE "^[[:space:]]*($R2R_syntax|$Shift_syntax)[[:space:]]*$" && return 0 || return 1
	return 0
}
chkIsyntx(){
	local instr="$1"

	commonSyntx		# Register & Hex immediate input syntax

	local MEM_syntax="(SB|SW|LB|LW)[[:space:]]+${Reg_syntax}${Comma_syntax}(${MEMref_syntax}|${HEX_syntax})"
	local L_syntax="(LI|LUI)[[:space:]]+${Reg_syntax}${Comma_syntax}${HEX_syntax}"
	local OP_syntax="(ADDI|NANDI|ORI)[[:space:]]+${Reg_syntax}${Comma_syntax}(${Reg_syntax}${Comma_syntax})?${HEX_syntax}"
	echo "$instr" | grep -qE "^[[:space:]]*($MEM_syntax|$OP_syntax|$L_syntax)[[:space:]]*$" && return 0 || return 1
}
chkJsyntx(){
	local instr="$1"

	commonSyntx		# Register & Hex immediate input syntax
	local B_syntax="B[[:space:]]+$HEX_syntax[[:space:]]+"
	local B_EQ_NE_syntax="B(NE|EQ)[[:space:]]+${Reg_syntax},[[:space:]]*$Reg_syntax,[[:space:]]*$HEX_syntax"
	echo "$instr" | grep -qE "^[[:space:]]*($B_syntax|$B_EQ_NE_syntax)[[:space:]]*$" && return 0 || return 1
}

## Operand fetching functions
getRItypeRd(){					# Returns Rd register in binary
	local instr="$1"
	local tmpR=""

	commonSyntx
	tmpR=$(echo $instr | grep -oE "^[[:space:]]*${INSTRS_NAMES}[[:space:]]+${Reg_syntax}" | grep -oE "${Reg_syntax}")
	tmpR=$(echo $tmpR | grep -oE "[[:digit:]]+")
	tmpR=$(cnvDec2Bin "$tmpR" 5)
	if echo $instr | grep -qE "^B[[:space:]]+";
	then
		((${#tmpR}==0)) && tmpR="00000"
	fi
	echo $tmpR
}
getRItypeRt(){					# Returns Rt register in binary
	local instr="$1"
	local tmpR=""

	commonSyntx
	local NOO=$(echo $instr | grep -oE "${Reg_syntax}" | wc -l)		# Number of operands
	((NOO==1)) && echo "00000" && return 0
	if ((NOO==2)) && echo $instr | grep -qE "${HEX_syntax}";
	then
		echo "00000" && return
	fi
	tmpR=$(echo $instr | grep -oE "${Reg_syntax}[[:space:]]*$" | grep -oE "${Reg_syntax}")
	tmpR=$(echo $tmpR | grep -oE "[[:digit:]]+")
	tmpR=$(cnvDec2Bin "$tmpR" 5)
	if echo $instr | grep -qE "^B[[:space:]]+";
	then
		((${#tmpR}==0)) && tmpR="00000"
	fi
	echo $tmpR
}
getRItypeRs(){					# Returns Rd register in binary
	local instr="$1"
	local tmpR=""

	commonSyntx
	local NOO=$(echo $instr | grep -oE "${Reg_syntax}" | wc -l)		# Number of operands
	if ((NOO==1));
	then
		if echo $instr | grep -qE "^(LI|LUI|SB|SW)[[:space:]]+";
		then
			tmpR="00000"
		else
			tmpR=$(getRItypeRd "$instr")
		fi
	elif ((NOO==2));
	then
		if echo $instr | grep -qE "${MEMref_syntax}";
		then
			tmpR=$(echo $instr | grep -oE "${MEMref_syntax}" | grep -oE "${Reg_syntax}")
			tmpR=$(echo $tmpR | grep -oE "[[:digit:]]+")
			tmpR=$(cnvDec2Bin "$tmpR" 5)
		else
			tmpR=$(echo $instr | grep -oE "^[[:space:]]*${INSTRS_NAMES}[[:space:]]+${Reg_syntax}${Comma_syntax}${Reg_syntax}" | grep -oE "${Reg_syntax}$")
			tmpR=$(echo $tmpR | grep -oE "[[:digit:]]+")
			tmpR=$(cnvDec2Bin "$tmpR" 5)
		fi
	elif ((NOO==3));
	then
		tmpR=$(echo $instr | grep -oE "^[[:space:]]*${INSTRS_NAMES}[[:space:]]+${Reg_syntax}${Comma_syntax}${Reg_syntax}" | grep -oE "${Reg_syntax}$")
		tmpR=$(echo $tmpR | grep -oE "[[:digit:]]+")
		tmpR=$(cnvDec2Bin "$tmpR" 5)

	fi
	if echo $instr | grep -qE "^B[[:space:]]+";
	then
		((${#tmpR}==0)) && tmpR="00000"
	fi
	echo $tmpR
}
getImmed(){
	local instr="$1"
	local tmpR=""

	commonSyntx
	if echo $instr | grep -qE "${MEMref_syntax}";
	then
		tmpR=$(echo $instr | grep -oE "[+-]?[[:digit:]]{1,4}\(" | grep -oE "[-+]?[[:digit:]]+")
		tmpR=$(cnvDec2Bin "$tmpR" 16)
	else
		tmpR=$(echo $instr | grep -oE "${HEX_syntax}[[:space:]]*$" | grep -oE "${HEX_syntax}")
		tmpR=$(echo $tmpR | grep -oE "[[:digit:]ABCDEF]{1,4}$")
		tmpR=$(cnvHex2Bin "$tmpR" 16)
	fi

	echo $tmpR
}

synErr="*SYNTAX ERROR* : MIPS_CHARIS_assembler.sh <CHARIS assembly instructions>"
inErr="*INPUT ERROR* : MIPS_CHARIS_assembler.sh <CHARIS assembly instructions>"
[ ${#} -ne 1 ] && echo $synErr && exit 1 # Invalid syntax error
[ ! -f "$1" ] && echo $inErr && exit 1 # Invalid input error
asblFile="$1"

#All CHARIS's Instructions and their corresponding opcodes, function codes and types.
INSTRs_ASBL=('ADD' 'SUB' 'AND' 'OR' 'NOT' 'NAND' 'NOR' 'SRA' 'SRL' 'SLL' 'ROL' 'ROR' 'LI' 'LUI' 'ADDI' 'NANDI' 'ORI' 'B' 'BEQ' 'BNE' 'LB' 'SB' 'LW' 'SW')
INSTRs_OPC=( '100000' '100000' '100000' '100000' '100000' '100000' '100000' '100000' '100000' '100000' '100000' '100000' '111000' '111001' '110000' '110010' '110011' '111111' '000000' '000001' '000011' '000111' '001111' '011111' )
INSTRs_FUNC=('110000' '110001' '110010' '110011' '110100' '110101' '110110' '111000' '111001' '111010' '111100' '111101' )
INSTRs_TYPE=('R' 'R' 'R' 'R' 'R' 'R' 'R' 'R' 'R' 'R' 'R' 'R' 'I' 'I' 'I' 'I' 'I' 'J' 'J' 'J' 'I' 'I' 'I' 'I')

#Instructions' 32bit format
RtypeFormat="<OPC><Rs><Rd><Rt>00000<func>"
ItypeFormat="<OPC><Rs><Rd><Immediate>"
JtypeFormat="<OPC><Rs><Rd><Immediate>"
binary=""


while read l;
do
	l=${l^^*}				# Instruction capitalized
	[[ ${l} =~ ^[[:space:]]*$ ]] && echo "00000000000000000000000000000000" && continue
	idx=$(getINSTRidx $(echo $l | grep -oE "^[^ ]+"))
	
	if [ ${INSTRs_TYPE[$idx]} = 'R' ];						# The instruction is R-type
	then
		chkRsyntx "$l" || { echo "*SYNTAX ERROR* : $l" && exit 1; }
		Rd=$(getRItypeRd "$l")							# Get Rd in binary
		Rs=$(getRItypeRs "$l")							# Get Rs in binary
		Rt=$(getRItypeRt "$l")							# Get Rt in binary
		binary=$(echo $RtypeFormat | sed -r "s/<OPC>/${INSTRs_OPC[$idx]}/")	# Replace <OPC> with instruction's opcode
		binary=$(echo $binary | sed -r "s/<func>/${INSTRs_FUNC[$idx]}/")	# Replace <func> with instruction's function
		binary=$(echo $binary | sed -r "s/<Rd>/${Rd}/")				# Replace <Rd> with instruction's register
		binary=$(echo $binary | sed -r "s/<Rs>/${Rs}/")				# Replace <Rs> with instruction's register
		binary=$(echo $binary | sed -r "s/<Rt>/${Rt}/")				# Replace <Rt> with instruction's register
		echo $binary
	elif [ ${INSTRs_TYPE[$idx]} = 'I' ];						# The instruction is I-type
	then
		chkIsyntx "$l" || { echo "*SYNTAX ERROR* : $l" && exit 1; }
		Rd=$(getRItypeRd "$l")							# Get Rd in binary
		Rs=$(getRItypeRs "$l")							# Get Rs in binary
		Immed=$(getImmed "$l")							# Get Immed in binary
		binary=$(echo $ItypeFormat | sed -r "s/<OPC>/${INSTRs_OPC[$idx]}/")	# Replace <OPC> with instruction's opcode
		binary=$(echo $binary | sed -r "s/<func>/${INSTRs_FUNC[$idx]}/")	# Replace <func> with instruction's function
		binary=$(echo $binary | sed -r "s/<Rd>/${Rd}/")				# Replace <Rd> with instruction's register
		binary=$(echo $binary | sed -r "s/<Rs>/${Rs}/")				# Replace <Rs> with instruction's register
		binary=$(echo $binary | sed -r "s/<Immediate>/${Immed}/")		# Replace <Immediate> with instruction's immediate
		echo $binary
	elif [ ${INSTRs_TYPE[$idx]} = 'J' ];						# The instruction is J-type
	then
		chkJsyntx "$l" || { echo "*SYNTAX ERROR* : $l" && exit 1; }
		Rd=$(getRItypeRd "$l")							# Get Rd in binary
		Rs=$(getRItypeRs "$l")							# Get Rs in binary
		Immed=$(getImmed "$l")							# Get Immed in binary
		binary=$(echo $JtypeFormat | sed -r "s/<OPC>/${INSTRs_OPC[$idx]}/")	# Replace <OPC> with instruction's opcode
		binary=$(echo $binary | sed -r "s/<Rd>/${Rd}/")				# Replace <Rd> with instruction's register
		binary=$(echo $binary | sed -r "s/<Rs>/${Rs}/")				# Replace <Rs> with instruction's register
		binary=$(echo $binary | sed -r "s/<Immediate>/${Immed}/")		# Replace <Immediate> with instruction's immediate
		echo $binary
	else
		echo "Invalid command \"$l\"" && exit 1
	fi
#	echo $l
done < $asblFile
