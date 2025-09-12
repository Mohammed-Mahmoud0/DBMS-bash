
#!/usr/bin/bash

# main menu functions
main_menu(){
    clear
    while true; do
    echo "      Main Menu "
    echo "1- Create Database "
    echo "2- List Databases "
    echo "3- Connect to Database "
    echo "4- Drop Database "
    echo "5- Exit "
    read -p "Enter your choice: " choice
    clear
    case $choice in
    	1) create_database ;;
    	2) list_databases ;;
    	3) connect_to_database ;;
		4) drop_database ;;
		5)
			echo "Good Bye"
			break
			;;
	    *) echo "Choose a valid number" ;;		        	        
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
    local database_dir=$1
    read -p "Enter table name: " table
    touch "$database_dir/$table"
    echo "Table created"
}

list_tables() {
    local database_dir=$1
    if [ ! -d "$database_dir" ]; then
        echo "Database not found"
    elif [ -z "$(ls -A "$database_dir")" ]; then
        echo "No Tables Created Yet"
    else
        ls "$database_dir"
    fi
	
}

drop_table() {
    local database_dir=$1
    read -p "Enter table name to drop: " table
    if [ -f "$database_dir/$table" ]; then
    	rm -f "$database_dir/$table"
    	echo "Table dropped"
	else
		echo "Table $table not found"
	fi
}

insert_into_table(){
	echo "insert not implemented yet"
}

select_from_table(){
	echo "select not implemented yet"
}

delete_from_table(){
	echo "delete not implemented yet"
}

update_table(){
	echo "update not implemented yet"
}

base_dir=".db"
         
main_menu     
            
        
