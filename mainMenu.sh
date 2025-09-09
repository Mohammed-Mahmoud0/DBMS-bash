
#!/usr/bin/bash

base_dir=".db"
clear
while true; do
    echo "      Main Menu "
    echo "1- Create Database "
    echo "2- List Databases "
    echo "3- Connect to Database "
    echo "4- Drop Database "
    echo "5- Exit "
    read -p "Enter your choice: " choice

    case $choice in
        1)
            read -p "Enter database name: " database_name
            database_dir="${database_name}${base_dir}"
            if [ -d "$database_dir" ]; then
                echo "Database already exists"
            else 
                mkdir "$database_dir"
                echo "Database created successfully"
            fi
            ;;
        2)
            ls -d *"$base_dir" 2>/dev/null || echo "No databases found"
            ;;
        3)
            read -p "Enter database name to connect: " database_name
            database_dir="${database_name}${base_dir}"
            if [ -d "$database_dir" ]; then
                cd "$database_dir"
                echo "Connected to $database_dir"
            else
                echo "Database not found"
            fi
            ;;
        4)
            read -p "Enter database name to drop: " database_name
            database_dir="${database_name}${base_dir}"
            if [ -d "$database_dir" ]; then
                rm -r "$database_dir"
                echo "Database deleted"
            else
                echo "Database not found"
            fi
            ;;
        5)
            echo "Good Bye"
            break
            ;;
        *)
            echo "Choose a valid number"
            ;;
    esac
done
