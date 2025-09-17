
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
			"Drop Database") drop_database ;;
			"Exit")
				zenity --info --text="Good Bye"
				break
				;;
			*) zenity --info --text="Choose a valid choice" ;;		        	        
		esac
	done
}

create_database(){
	database_name=$(zenity --entry \
        --title="Create Database" \
        --text="Enter database name:")
        
    if [ -z "$database_name" ]; then
	    zenity --warning --text="No database name entered."
	    return
	fi
        
	database_dir="${database_name}${base_dir}"
	
	
	
	if [ -d "$database_dir" ]; then
		zenity --error --text="Database '$database_name' already exists!"
	else 
		mkdir "$database_dir"
		zenity --info --text="Database '$database_name' created successfully."
	fi
}

list_databases(){
	databases=$(find . -maxdepth 1 -type d -name "*.db" -printf "%f\n")
	
	if [ -z "$databases" ]; then
        zenity --warning --text="No databases created yet."
    else
        echo "$databases" | zenity --text-info \
            --title="List of Databases" \
            --width=400 --height=300
    fi
    
}

connect_to_database(){

	databases=$(find . -maxdepth 1 -type d -name "*.db" -printf "%f\n")

    if [ -z "$databases" ]; then
        zenity --warning --text="No databases available. Please create one first."
        return
    fi
	
	database_name=$(echo "$databases" | zenity --list \
        --title="Connect to Database" \
        --text="Select a database to connect:" \
        --column="Database Name" \
        --width=400 --height=300)
        
 	[ -z "$database_name" ] && return
	
	
	database_dir="${database_name}"
    cd "$database_dir" || return
    
	zenity --info --text="Connected to $database_dir"
	
	while true; do
	    db_choice=$(zenity --list \
            --title="Database Menu ($database_name)" \
            --text="Choose an option:" \
            --radiolist \
            --column="Select" --column="Option" \
            TRUE "Create Table" \
            FALSE "List Tables" \
            FALSE "Drop Table" \
            FALSE "Insert Into Table" \
            FALSE "Select From Table" \
            FALSE "Delete From Table" \
            FALSE "Update Table" \
            FALSE "Back to Main Menu" \
            --width=400 --height=350)
            
	    case $db_choice in
	        "Create Table") create_table "$database_dir" ;;
            "List Tables") list_tables "$database_dir" ;;
            "Drop Table") drop_table "$database_dir" ;;
            "Insert Into Table") insert_into_table ;;
            "Select From Table") select_from_table_menu ;;
            "Delete From Table") delete_from_table ;;
            "Update Table") update_table ;;
            "Back to Main Menu"|"" ) break ;;
            *) zenity --error --text="Invalid choice" ;;
	    esac
	done
}

drop_database(){
	databases=$(find . -maxdepth 1 -type d -name "*.db" -printf "%f\n")
	if [ -z "$databases" ]; then
        zenity --warning --text="No databases found to drop."
        return
    fi

	database_name=$(echo "$databases" | zenity --list \
        --title="Drop Database" \
        --text="Select a database to delete:" \
        --column="Database Name" \
        --width=400 --height=300)
        
    [ -z "$database_name" ] && return
    
    zenity --question --text="Are you sure you want to delete database '$database_name'?" \
        --width=300
    if [ $? -eq 0 ]; then
        rm -r "./$database_name"
        zenity --info --text="Database '$database_name' deleted successfully."
    fi
}


# database functions (when connect to database)
create_table() {
    table=$(zenity --entry \
        --title="Create Table" \
        --text="Enter table name:")
        
    [ -z "$table" ] && return
    
    local table_path="$table"
	local meta_path="$table_path.meta"
	
	if [ -e "$table_path" ] || [ -e "$meta_path" ]; then
        zenity --error --text="Table '$table' already exists."
        return 1
    fi
    
    num_cols=$(zenity --entry \
        --title="Number of Columns" \
        --text="Enter the number of columns:")
    [ -z "$num_cols" ] && return
    
    local -a col_names col_types col_pks
    local pk_set=0
    
    for ((i=1; i<=num_cols; i++)); do
        while true; do
            colname=$(zenity --entry \
                --title="Column $i" \
                --text="Enter name of column #$i:")
            [ -z "$colname" ] && return

            local check_dup=0
            for name in "${col_names[@]}"; do
                if [ "$name" = "$colname" ]; then
                    check_dup=1
                    break
                fi
            done
            if [ $check_dup -eq 1 ]; then
                zenity --error --text="Column name '$colname' already exists. Please enter another."
                continue
            fi
            col_names+=("$colname")
            break
        done
		
		datatype=$(zenity --list \
            --title="Column $i: $colname" \
            --text="Choose datatype:" \
            --radiolist \
            --column="Select" --column="Datatype" \
            TRUE "string" \
            FALSE "int" \
            --width=300 --height=200)
        datatype="${datatype:-string}"
        col_types+=("$datatype")
		
		while true; do
            ans=$(zenity --list \
                --title="Primary Key" \
                --text="Make '$colname' the primary key?" \
                --radiolist \
                --column="Select" --column="Option" \
                TRUE "No" \
                FALSE "Yes" \
                --width=250 --height=200)

            case "$ans" in
                "Yes")
                    if [ $pk_set -eq 1 ]; then
                        zenity --error --text="Primary key already set on another column. Only one PK allowed."
                        continue
                    fi
                    col_pks+=("pk")
                    pk_set=1
                    break
                    ;;
                "No"|"" )
                    col_pks+=("nokey")
                    break
                    ;;
                *) zenity --error --text="Please select Yes or No." ;;
            esac
        done
    done
    	
	
	
	touch "$meta_path"
	for idx in "${!col_names[@]}"; do
		echo "${col_names[$idx]}:${col_types[$idx]}:${col_pks[$idx]}" >> "$meta_path"
	done
	
	touch "$table_path"
	
	zenity --info --text="Table '$table' created successfully!"
	return 0
}

list_tables() {
	tables=$(ls | grep -vE '\.meta$|\.txt$')

   	if [ -z "$tables" ]; then
        zenity --warning --text="No tables created yet in this database."
        return
    fi

    echo "$tables" | zenity --text-info \
        --title="List of Tables in $(basename "$PWD")" \
        --width=400 --height=300
	
}

drop_table() {
    tables=$(ls | grep -vE '\.meta$|\.txt$')

    if [ -z "$tables" ]; then
        zenity --warning --text="No tables available to drop in this database."
        return
    fi

    table=$(echo "$tables" | zenity --list \
        --title="Drop Table" \
        --text="Select a table to drop:" \
        --column="Table Name" \
        --width=400 --height=300)

    if [ -z "$table" ]; then
        return
    fi

    zenity --question --text="Are you sure you want to drop the table '$table'?"
    if [ $? -eq 0 ]; then
        rm -f "$table" "$table.meta"
        zenity --info --text="Table '$table' dropped successfully."
    else
        zenity --info --text="Drop table cancelled."
    fi
}

insert_into_table() {
    local database_dir="$PWD"

    tables=$(ls | grep -vE '\.meta$|\.txt$')
    if [ -z "$tables" ]; then
        zenity --warning --text="No tables available to insert into."
        return 1
    fi

    table=$(echo "$tables" | zenity --list \
        --title="Insert Into Table" \
        --text="Select a table:" \
        --column="Table Name" \
        --width=400 --height=300)

    if [ -z "$table" ]; then
        return 1
    fi

    local table_path="$database_dir/$table"
    local meta_path="$table_path.meta"

    if [ ! -f "$meta_path" ] || [ ! -f "$table_path" ]; then
        zenity --error --text="Table or meta file not found. Make sure the table exists."
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
        zenity --error --text="Empty schema. Try recreating the table."
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
            val=$(zenity --entry \
                --title="Insert Into Table" \
                --text="Enter value for '${cname}' (${ctype}):")

            if [ -z "$val" ]; then
                zenity --warning --text="Value cannot be empty."
                continue
            fi

            if [[ "$val" == *"|"* ]]; then
                zenity --warning --text="Character '|' is not allowed (reserved as field separator)."
                continue
            fi

            if [ "$ctype" = "int" ]; then
                if ! [[ "$val" =~ ^-?[0-9]+$ ]]; then
                    zenity --warning --text="Invalid integer. Try again."
                    continue
                fi
            fi

            if [ "$i" -eq "$pk_index" ]; then
                if awk -F'|' -v c="$((i+1))" -v v="$val" '$c==v {found=1; exit} END{exit !found}' "$table_path"; then
                    zenity --warning --text="Primary key value '$val' already exists. Enter a unique value."
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
    zenity --info --text="Row inserted successfully into '$table'."
    return 0
}



select_from_table_menu() {
    chooseTable || return

    # use global CHOSEN_TABLE directly
    if [ -z "$CHOSEN_TABLE" ]; then
        zenity --warning --text="No table selected."
        return 1
    fi

    choice=$(zenity --list \
        --title="Select Menu" \
        --text="Choose a selection option for table: $CHOSEN_TABLE" \
        --radiolist \
        --column="Select" --column="Option" \
        TRUE "Select all" \
        FALSE "Select row using PK" \
        FALSE "Select range of rows" \
        FALSE "Exit" \
        --width=400 --height=300)

    case "$choice" in
        "Select all") selectAll "$CHOSEN_TABLE" ;;
        "Select row using PK") selectRow "$CHOSEN_TABLE" ;;
        "Select range of rows") selectRange "$CHOSEN_TABLE" ;;
        "Exit") return ;;
        *) zenity --error --text="Invalid choice." ;;
    esac
}


chooseTable() {
    tables=$(ls -1 | grep -vE '\.meta$|\.txt$')

    if [ -z "$tables" ]; then
        zenity --warning --text="No tables available in this database."
        return 1
    fi

    CHOSEN_TABLE=$(echo "$tables" | zenity --list \
        --title="Choose Table" \
        --text="Select a table:" \
        --column="Table Name" \
        --width=400 --height=300)

    [ -z "$CHOSEN_TABLE" ] && return 1
    return 0
}




selectAll() {
    local table="$1"

    if [ -s "$table" ]; then
        zenity --text-info --title="Table: $table" --filename="$table" --width=600 --height=400
    else
        zenity --warning --text="Table '$table' is empty."
    fi
}

selectRow() {
    local table="$1"
    local meta_path="$table.meta"

    if [ ! -f "$meta_path" ]; then
        zenity --error --text="Metadata not found for $table"
        return
    fi

    local pk_col
    pk_col=$(grep -n ":pk" "$meta_path" | cut -d: -f1)
    if [ -z "$pk_col" ]; then
        zenity --warning --text="No primary key defined for $table"
        return
    fi

    pk_value=$(zenity --entry --title="Search by PK" --text="Enter value for Primary Key:")
    [ -z "$pk_value" ] && return

    result=$(awk -F"|" -v col="$pk_col" -v val="$pk_value" '$col == val { print; found=1 } END { if (!found) print "No row found with PK=" val }' "$table")

    echo "$result" | zenity --text-info --title="Search Result" --width=600 --height=400
}

selectRange() {
    local table="$1"
    local total_lines
    total_lines=$(wc -l < "$table")
    if [ "$total_lines" -eq 0 ]; then
        zenity --warning --text="Table '$table' is empty."
        return
    fi

    range=$(zenity --entry --title="Select Range" \
        --text="Enter a valid range (example: 1 5)\nMax rows: $total_lines")
    [ -z "$range" ] && return

    read -r start end <<< "$range"

    if ! [[ "$start" =~ ^[0-9]+$ && "$end" =~ ^[0-9]+$ ]]; then
        zenity --error --text="Invalid input. Must be numbers."
        return
    fi

    if [ "$start" -lt 1 ] || [ "$end" -gt "$total_lines" ] || [ "$start" -gt "$end" ]; then
        zenity --error --text="Invalid range."
        return
    fi

    result=$(sed -n "${start},${end}p" "$table")
    echo "$result" | zenity --text-info --title="Range Result" --width=600 --height=400
}


delete_from_table() {
    local database_dir="$PWD"

    # List available tables
    tables=$(ls | grep -vE '\.meta$|\.txt$')
    if [ -z "$tables" ]; then
        zenity --warning --text="No tables available to delete from."
        return 1
    fi

    table_name=$(echo "$tables" | zenity --list \
        --title="Delete From Table" \
        --text="Select a table:" \
        --column="Table Name" \
        --width=400 --height=300)

    if [ -z "$table_name" ]; then
        return 1
    fi

    table_path="$database_dir/$table_name"

    if [ ! -f "$table_path" ]; then
        zenity --error --text="Table '$table_name' not found."
        return 1
    fi

    total_rows=$(wc -l < "$table_path")
    if [ "$total_rows" -eq 0 ]; then
        zenity --warning --text="The table '$table_name' is empty. No rows to delete."
        return 1
    fi

    # Display table content with line numbers
    rows=$(nl -w 3 -s '. ' "$table_path")
    row_number=$(echo "$rows" | zenity --list \
        --title="Delete From Table" \
        --text="Select a row to delete from '$table_name':" \
        --column="Row" \
        --width=600 --height=400)

    if [ -z "$row_number" ]; then
        return 1
    fi

    # Extract only the line number (first field before ". ")
    row_number=$(echo "$row_number" | awk -F'.' '{print $1}' | xargs)


    preview=$(sed -n "${row_number}p" "$table_path")

    zenity --question \
        --title="Confirm Deletion" \
        --text="Are you sure you want to delete row $row_number?\n\n$preview"

    if [ $? -eq 0 ]; then
        sed -i "${row_number}d" "$table_path"
        echo "Deleted row $row_number from $table_name" >> delete_log.txt
        zenity --info --text="Row $row_number has been deleted from '$table_name'."
    else
        zenity --info --text="Deletion canceled."
    fi
}

update_table() {
    local database_dir="$PWD"

    tables=$(ls | grep -vE '\.meta$|\.txt$')
    if [ -z "$tables" ]; then
        zenity --warning --text="No tables available to update."
        return 1
    fi

    table_name=$(echo "$tables" | zenity --list \
        --title="Update Table" \
        --text="Select a table:" \
        --column="Table Name" \
        --width=400 --height=300)

    if [ -z "$table_name" ]; then
        return 1
    fi

    if [ ! -s "$table_name" ]; then
        zenity --warning --text="The table '$table_name' is empty. Nothing to update."
        return 1
    fi

    total_rows=$(wc -l < "$table_name")

    rows=$(nl -w 3 -s '. ' "$table_name")
    row_number=$(echo "$rows" | zenity --list \
        --title="Select Row" \
        --text="Choose a row to update in '$table_name':" \
        --column="Row" \
        --width=600 --height=400)

    if [ -z "$row_number" ]; then
        return 1
    fi

    row_number=$(echo "$row_number" | awk -F'.' '{print $1}' | xargs)
    if [ "$row_number" -lt 1 ] || [ "$row_number" -gt "$total_rows" ]; then
        zenity --error --text="Invalid row number."
        return 1
    fi

    old_row=$(sed -n "${row_number}p" "$table_name")
    old_word=$(zenity --entry \
        --title="Old Value" \
        --text="Enter the word you want to replace in row $row_number:\n\n$old_row")

    if [ -z "$old_word" ]; then
        zenity --error --text="Old value cannot be empty."
        return 1
    fi

    new_word=$(zenity --entry \
        --title="New Value" \
        --text="Enter the new value to replace '$old_word':")

    if [ -z "$new_word" ]; then
        zenity --error --text="New value cannot be empty."
        return 1
    fi

    sed -i "${row_number}s/${old_word}/${new_word}/g" "$table_name"

    new_row=$(sed -n "${row_number}p" "$table_name")
    zenity --info --text="Row updated successfully!\n\nBefore: $old_row\nAfter:  $new_row"
}

base_dir=".db"
         
main_menu     
            
        
