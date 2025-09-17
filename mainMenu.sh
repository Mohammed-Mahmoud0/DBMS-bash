
#!/usr/bin/bash

# main menu functions
main_menu(){
    while true; do
		choice=$(zenity --list \
			--title="Main Menu" \
			--text="Choose an option:" \
			--radiolist \
			--column="Select" --column="Option" \
			True "Create Database" \
			False "List Databases" \
			False "Connect to Database" \
			False "Drop Database" \
			False "Exit" \
			--width=400 --height=300)
    
		case $choice in
			"Create Database") create_database ;;
			"List Databases") list_databases ;;
			"Connect to Database") connect_to_database ;;
			"Drob Database") drop_database ;;
			"Exit")
				zenity --info --text="Good Bye"
				break
				;;
			*) zenity --info --text="Choose a valid number" ;;		        	        
		esac
	done
}

create_database(){
	read -p "Enter database name: " database_name
	database_dir="${database_name}${base_dir}"
	if [ -d "$database_dir" ]; then
		echo "Database already exists"
	else 
		mkdir "$database_dir"
	echo "Database created successfully"
	fi
}

list_databases(){
	ls -d *"$base_dir" 2>/dev/null || echo "No databases found"
}

connect_to_database(){
	read -p "Enter database name to connect: " database_name
	database_dir="${database_name}${base_dir}"
    if [ -d "$database_dir" ]; then
	cd "$database_dir" 
	echo "Connected to $database_dir"
	while true; do
	    echo "      Database Menu ($database_name)"
	    echo "1- Create Table"
	    echo "2- List Tables"
	    echo "3- Drop Table"
	    echo "4- Insert Into Table"
	    echo "5- Select From Table"
	    echo "6- Delete From Table"
	    echo "7- Update Table"
	    echo "8- Back to Main Menu"
	    read -p "Enter your choice: " db_choice
	    clear
	    case $db_choice in
	        1) create_table "$database_dir" ;;	            
	        2) list_tables "$database_dir" ;;	            
	        3) drop_table "$database_dir" ;;
	        4) insert_into_table ;;  
	        5) select_from_table ;;
	        6) delete_from_table ;;
	        7) update_table ;;          
	        8) break ;;           
	        *) echo "Invalid choice" ;; 
	    esac
	done
    else
	echo "Database not found"
    fi
}

drop_database(){
	read -p "Enter database name to drop: " database_name
    database_dir="${database_name}${base_dir}"
    if [ -d "$database_dir" ]; then
        rm -r "$database_dir"
        echo "Database deleted"
    else
        echo "Database not found"
    fi
}


# database functions (when connect to database)
create_table() {
    read -p "Enter table name: " table
    local table_path="$table"
	local meta_path="$table_path.meta"
	
	if [ -e "$table_path" ] || [ -e "$meta_path" ]; then
        echo "Table already exists."
        return 1
    fi
    
    local num_cols
    read -p "Number of Columns: " num_cols
    
    local -a col_names col_types col_pks
    local pk_set=0
    
    for ((i=1; i<=num_cols; i++)); do
    	while true; do
    		read -p "Name Of Column #$i: " colname
    		local check_dup=0
    		for name in "${col_names[@]}"; do
    			if [ "$name" = "$colname" ]; then
    				check_dup=1; break
				fi
			done
			if [ $check_dup -eq 1 ]; then
				echo "Column name '$colname' already exist. write another pls"
				continue
			fi
			col_names+=("$colname")
			break
		done
		
		while true; do
			read -p "Enter Datatype for '$colname' (int/string) string is the default: " datatype
			datatype="${datatype:-string}"
			datatype="${datatype,,}"
			if [[ "$datatype" = "int" || "$datatype" = "string" ]]; then
				col_types+=("$datatype")
				break
			else
				echo "Please Choose From Allowed datatypes: int, string"
			fi
		done
		
		while true; do
			read -p "Do You want to make '$colname' Primary Key (y/n) n is the default: " ans
			ans="${ans:-n}"
			case "${ans,,}" in
				y)
					if [ $pk_set -eq 1 ]; then
						echo "Primary key already set on another column. Only one PK allowed, choose another pls"
		                continue
		            fi
		            col_pks+=("pk")
		            pk_set=1
		            break
		            ;;
		        n)
		        	col_pks+=("nokey")
		        	break
		        	;;
		    	*) echo "please enter y or n" ;;
	    	esac
    	done
	done
	
	touch "$meta_path"
	for idx in "${!col_names[@]}"; do
		echo "${col_names[$idx]}:${col_types[$idx]}:${col_pks[$idx]}" >> "$meta_path"
	done
	
	touch "$table_path"
	
	echo "Table '$table' Created successfully."
	echo "You can find the schema in: $meta_path"
	return 0
}

list_tables() {
    if [ ! -d "$PWD" ]; then
        echo "Database not found"
    elif [ -z "$(ls -A "$PWD")" ]; then
        echo "No Tables Created Yet"
    else
        ls | grep -vE '\.meta$|\.txt$'
    fi
	
}

drop_table() {
    read -p "Enter table name to drop: " table
    if [ -f "$table" ]; then
    	rm -f "$table"
    	rm -f "$table.meta"
    	echo "Table dropped"
	else
		echo "Table $table not found"
	fi
}

insert_into_table(){
	local database_dir="$PWD"
	read -r -p "Enter table name to insert into: " table
	local table_path="$database_dir/$table"
	local meta_path="$table_path.meta"
	
	if [ ! -f "$meta_path" ] || [ ! -f "$table_path" ]; then
        echo "Table or meta file not found. Make sure the table exists."
        return 1
    fi
    
    local -a col_names col_types col_pks
    while IFS=':' read -r cname ctype cpk; do
        col_names+=("$cname")
        col_types+=("$ctype")
        col_pks+=("$cpk")
    done < "$meta_path"
    
    local num_cols=${#col_names[@]}
    if [ "$num_cols" -eq 0 ]; then
        echo "Empty schema,try to delete table and create it again. Aborting..."
        return 1
    fi
    
    local pk_index=-1
    for i in "${!col_pks[@]}"; do
        if [ "${col_pks[$i]}" = "pk" ]; then
            pk_index=$i
            break
        fi
    done
    
    local -a values
    for i in $(seq 0 $((num_cols-1))); do
        local cname="${col_names[$i]}"
        local ctype="${col_types[$i]}"
        
    	while true; do
            read -r -p "Enter value for '${cname}' (${ctype}): " val

            if [ -z "$val" ]; then
                echo "Value cannot be empty. Try again."
                continue
            fi
            
            if [[ "$val" == *"|"* ]]; then
                echo "Character '|' is not valid because it reserved as field separator."
                continue
            fi

            if [ "$ctype" = "int" ]; then
                if ! [[ "$val" =~ ^-?[0-9]+$ ]]; then
                    echo "Invalid integer. Try again."
                    continue
                fi
            fi

            if [ "$i" -eq "$pk_index" ]; then
    			if awk -F'|' -v c="$((i+1))" -v v="$val" '$c==v {found=1; exit} END{exit !found}' "$table_path"; then
        			echo "Primary key value '$val' already exists. Enter a unique value."
        			continue
    			fi
			fi

            values+=("$val")
            break
        done
    done
    
    local row
    row=$(IFS="|"; echo "${values[*]}")

    echo "$row" >> "$table_path"
    echo "Row inserted successfully into '$table'."
    return 0
}

select_from_table(){
    selectMenu
}

function selectMenu {
    echo "======================================================="
    echo "     Select Menu for Database Management System        "
    echo "======================================================="
    echo " "
    select x in "1- Select all" "2- select row using PK" "3- select range of rows" "4- exit"
    do
        case $REPLY in 
            1) selectAll; break;;
            2) selectRow; break;; 
            3) selectRange; break;;
            4) break;;
            *) echo "Invalid choice, try again";;
        esac
    done

}
chooseTable() {
    local tables=$(list_tables "$database_dir")
    
    if [ -z "$tables" ]; then
        echo "No tables available in this database."
        return 1
    fi

    echo "Available tables:"
    select table in $tables; do
        if [ -n "$table" ]; then
            echo "You selected table: $table"
            echo "$table"   # return table name
            return 0
        else
            echo "Invalid choice, try again."
        fi
    done
}

selectAll() {
    local table=$(chooseTable) || return

    echo "========== Table: $table =========="
    cat "$table_path"
    echo "==================================="
}


selectRow() {
    local table=$(chooseTable) || return
    local table_path="$database_dir/$table"
    local meta_path="$table_path.meta"

    if [ ! -f "$meta_path" ]; then
        echo "Metadata not found"
        return
    fi

    local pk_col=$(grep -n ":pk" "$meta_path" | cut -d: -f1)
    if [ -z "$pk_col" ]; then
        echo "No primary key defined for this table"
        return
    fi

    read -p "Enter value for primary key: " pk_value

    awk -F"|" -v col="$pk_col" -v val="$pk_value" '
        $col == val { print; found=1 }
        END { if (!found) print "No row found with PK=" val }
    ' "$table_path"    

}

selectRange() {
    local table=$(chooseTable) || return
    local table_path="$database_dir/$table"


    local total_lines=$(wc -l < "$table_path")
    if [ "$total_lines" -eq 0 ]; then
        echo "Table is empty"
        return
    fi

    echo "Write a valid range from 1 to $total_lines (example: 1 5)"
    read start end

    if ! [[ "$start" =~ ^[0-9]+$ && "$end" =~ ^[0-9]+$ ]]; then
        echo "Invalid input, must be numbers"
        return
    fi

    if [ "$start" -lt 1 ] || [ "$end" -gt "$total_lines" ] || [ "$start" -gt "$end" ]; then
        echo "Invalid range"
        return
    fi

    sed -n "${start},${end}p" "$table_path"
}

delete_from_table(){
	
	echo "Delete From Table"

    while true; do
        echo "Available tables:"
        ls  2>/dev/null
        read -p "Enter the table name to delete from:" table_name

        # Ensure the table name input is valid
        if [[ -z "$table_name" || ! "$table_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
            echo "Invalid name ."
            continue
        fi
        
        if [ -f "$table_name" ]; then
            break
        else
            echo "Error: Table $table_name does not exist."
            continue
        fi
    done
    
    while true; do
        echo " table $table_name Contains :"
        
        # Display the table with row numbers
        nl -w 3 -s '. ' "$table_name"
        
        read  -p " Enter the row number to delete: " row_number
        
        # Validate that the row number is a positive integer
        if [[ ! "$row_number" =~ ^[0-9]+$ ]] || [ "$row_number" -lt 1 ]; then
            echo "Invalid row number."
            continue
        fi
        
        # Check if the row number is within the range of existing rows
        total_rows=$(wc -l < "$table_name")
        
        # Check for empty tables
        if [ "$total_rows" -eq 0 ]; then
            echo "The table $table_name is empty. No rows to delete."
            continue
        fi
        if [ "$row_number" -gt "$total_rows" ]; then
            echo "Row number $row_number is out of range. The table has $total_rows rows."
            continue
        fi

        # Prevent deletion of rows 1 
        if [ "$row_number" -eq 1 ] ; then
            echo "Row 1 cannot be deleted. "
            continue
        fi

        # Preview the row to delete
        echo "Preview of row to delete:"
        sed -n "${row_number}p" "$table_name"
        
        # Confirm deletion
        while true; do
            read -p "Are you sure you want to delete row $row_number? (yes/no) " confirm
            
            if echo "$confirm" | grep -iq "^yes$"; then   
		# Delete the specified row
                sed -i "${row_number}d" "$table_name"
                echo "Row $row_number has been deleted from $table_name."
                echo " Deleted row $row_number from $table_name" >> delete_log.txt
                break
            elif echo "$confirm" | grep -iq "^no$"; then
                echo "Deletion canceled."
                break
            else
                echo "Invalid response. Please enter 'yes' or 'no'."
            fi
        done

        break
    done
}

update_table(){
    echo "Update From Table"

    while true; do
        echo "Available tables:"
        ls 2>/dev/null
        read -p "Enter the table name to update: " table_name

        if [[ -z "$table_name" || ! "$table_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
            echo "Invalid name."
            continue
        fi

        if [ -f "$table_name" ]; then
            break
        else
            echo "Error: Table $table_name does not exist."
            continue
        fi
    done

    if [ ! -s "$table_name" ]; then
        echo "The table $table_name is empty. Nothing to update."
        return
    fi

    echo "Table $table_name contents:"
    nl -w 3 -s '. ' "$table_name"

    read -p "Enter the row number to update: " row_number
    total_rows=$(wc -l < "$table_name")

    if [[ ! "$row_number" =~ ^[0-9]+$ ]] || [ "$row_number" -lt 1 ] || [ "$row_number" -gt "$total_rows" ]; then
        echo "Invalid row number."
        return
    fi

    echo "Selected row:"
    sed -n "${row_number}p" "$table_name"

    read -p "Enter the word you want to replace: " old_word
    read -p "Enter the new word: " new_word

    if [ -z "$old_word" ] || [ -z "$new_word" ]; then
        echo "Old and new values cannot be empty."
        return
    fi

    sed -i "${row_number}s/${old_word}/${new_word}/g" "$table_name"

    echo "Row updated successfully!"
    echo "Updated row:"
    sed -n "${row_number}p" "$table_name"
}


base_dir=".db"
         
main_menu     
            
        
