#!/bin/bash
# Generador de archivos .cue para ArkOS
# .cue file generator for ArkOS
# Autor: Davisito
# Author: Davisito
# Este script crea un archivo .cue a partir de un archivo .bin
# This script creates a .cue file from a .bin file
# seleccionado por el usuario, utilizando la herramienta 'dialog'
# selected by the user, using the 'dialog' tool
# para la interfaz de usuario.
# for the user interface.

# --- Configuracion inicial para ArkOS2 ---
# --- Initial setup for ArkOS2 ---
# Dar permisos al tty para la salida
# Grant permissions to the tty for output
sudo chmod 666 /dev/tty1
# Limpiar
# Clear
reset

# Ocultar el cursor
# Hide the cursor
printf "\e[?25l" > /dev/tty1
# Limpiar dialogo
# Clear dialog
dialog --clear
# Variables de configuracion para los cuadros de dialogo
# Configuration variables for dialog boxes
height="15"
width="55"

# Configuracion del terminal y las fuentes
# Terminal and font configuration
export TERM=linux
export XDG_RUNTIME_DIR=/run/user/$UID/

# Eliminar procesos existentes de teclado en pantalla
# Kill existing on-screen keyboard processes
pgrep -f gptokeyb | sudo xargs kill -9
pgrep -f osk.py | sudo xargs kill -9
# Reset de la pantalla
# Screen reset
printf "\033c" > /dev/tty1
# Texto empiece de ejecucion
# Execution start text
printf "Starting CUE generator. Please wait..." > /dev/tty1

# ------------------- Variables globales ------------------
# ------------------- Global variables ------------------
# Solo se asigna cuando el usuario ACEPTA explícitamente ('.' o archivo).
# It's only assigned when the user explicitly ACCEPTS ('.' or a file).
# En cancelación debe quedar vacío.
# On cancellation, it must be empty.
End_Path=""

# Funcion para salir del menu y restablecer la terminal
# Function to exit the menu and reset the terminal
Exit_Menu() {
    printf "\033c" > /dev/tty1
    if [[ ! -z $(pgrep -f gptokeyb) ]]; then
        pgrep -f gptokeyb | sudo xargs kill -9
    fi
    if [[ ! -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
        if test ! -z "$(cat /home/ark/.config/.DEVICE | grep RG503 | tr -d '\0')"
        then
            sudo setfont /usr/share/consolefonts/Lat7-TerminusBold20x10.psf.gz
        elif test ! -z "$(cat /home/ark/.config/.DEVICE | grep RGB20PRO | tr -d '\0')"
        then
            sudo setfont /usr/share/consolefonts/Lat7-TerminusBold32x16.psf.gz
        else
            sudo setfont /usr/share/consolefonts/Lat7-TerminusBold22x11.psf.gz
        fi
    fi
    # Mostrar el cursor de nuevo
    # Show the cursor again
    printf "\e[?25h" > /dev/tty1
    exit 0
}

Main_Menu() {
    while true; do
        opcion=$(dialog --backtitle "CUE Generator for ArkOS" \
                --title "Main Menu" \
                --menu "Select the required mode for the .bin" \
                $height $width 5 \
                1 "MODE2/2352 (ps1 Default)" \
                2 "MODE1/2352 (ps1 Alternative)" \
                3 "MODE1/2048 (Sega CD, PC Engine, Neo Geo)" \
                4 "MODE2/2336 (Saturn, ps1, 3DO)" \
                5 "AUDIO" \
                2>&1 >/dev/tty1)

        case $opcion in
            1)
                Mode="MODE2/2352"
                echo "You selected MODE2/2352" >/dev/tty1
                if File_Selector "/roms"; then
                    Cue_Maker "$Mode" "$End_Path"
                fi
                ;;
            2)
                Mode="MODE1/2352"
                echo "You selected MODE1/2352" >/dev/tty1
                if File_Selector "/roms"; then
                    Cue_Maker "$Mode" "$End_Path"
                fi
                ;;
            3)
                Mode="MODE1/2048"
                echo "You selected MODE1/2048" >/dev/tty1
                if File_Selector "/roms"; then
                    Cue_Maker "$Mode" "$End_Path"
                fi
                ;; 
            4)
                Mode="MODE2/2336"
                echo "You selected MODE2/2336" >/dev/tty1
                if File_Selector "/roms"; then
                    Cue_Maker "$Mode" "$End_Path"
                fi
                ;;
            5)
                Mode="AUDIO"
                echo "You selected AUDIO" >/dev/tty1
                if File_Selector "/roms"; then
                    Cue_Maker "$Mode" "$End_Path"
                fi
                ;;
            *)
                # Si el usuario cancela o sale, se cierra el script.
                # If the user cancels or exits, the script closes.
                echo "Exiting script. Goodbye!" >/dev/tty1
                break
                ;;
        esac

        # Comprobacion de salida si el usuario cancelo la operacion
        # Check for exit if the user canceled the operation
        if [[ -z "$End_Path" ]]; then
            break
        fi
    done
}

# Funcion para seleccionar un archivo o directorio
# Function to select a file or directory
File_Selector() {
    # Guardar el directorio de inicio
    # Save the starting directory
    local start_dir="$1"

    # Restablecer la pantalla y el cursor
    # Reset the screen and the cursor
    printf "\e[?25l" > /dev/tty1
    dialog --clear

    local current_dir="$start_dir"
    local selected_path=""

    # Asegurar que los globs vacios no devuelvan el patron literal
    # Ensure that empty globs don't return the literal pattern
    shopt -s nullglob

    while true; do
        # Construir items del menu desde cero en cada iteracion
        # Build menu items from scratch in each iteration
        local menu_items=()
        menu_items+=("." "Select this directory")
        menu_items+=(".." "Go up one level")

        # Listamos los contenidos del directorio actual
        # List the contents of the current directory
        for entry in "$current_dir"/*; do
            local name
            name=$(basename "$entry")
            if [ -d "$entry" ]; then
                menu_items+=("$name/" "Directory")
            elif [ -f "$entry" ]; then
                menu_items+=("$name" "File")
            fi
        done

        # Mostrar el menu con dialog
        # Show the menu with dialog
        # Usamos --output-fd 1 para que SOLO la seleccion vaya por stdout (que capturamos),
        # We use --output-fd 1 so that ONLY the selection goes to stdout (which we capture),
        # y mandamos la interfaz (stderr) al TTY1 para evitar "residuos" en la variable.
        # and we send the interface (stderr) to TTY1 to avoid "residue" in the variable.
        local selection
        # Mostrar el menu con dialog y capturar codigo de salida
        # Show the menu with dialog and capture the exit code
        selection=$(dialog \
            --clear \
            --backtitle "CUE Generator for ArkOS" \
            --title "Select a .bin file" \
            --menu "Current directory: $current_dir" 20 70 15 \
            "${menu_items[@]}" \
            --output-fd 1 \
            2>/dev/tty1)
        rc=$?

        case $rc in
            0)
                # OK procesar seleccion
                # OK process selection
                ;;
            1)
                # Cancelar no guardar nada y volver al menu principal
                # Cancel do not save anything and return to the main menu
                End_Path=""
                dialog --msgbox "No path/file was selected" 8 60 2>/dev/tty1
                return 1
                ;;
            255)
                # ESC o Select+Start salir del script inmediatamente
                # ESC or Select+Start exit the script immediately
                Exit_Menu
                ;;
        esac

        case "$selection" in
            ".")
                # Usar este directorio para todos los .bin
                # Use this directory for all .bin files
                selected_path="$current_dir"
                End_Path="$selected_path"
                return 0
                ;;
            "..")
                # Subir un nivel de directorio
                # Go up one directory level
                local parent
                parent=$(dirname "$current_dir")

                # Evitar quedarse en bucle si ya estamos en /
                # Avoid getting stuck in a loop if we are already at /
                if [ "$parent" != "$current_dir" ]; then
                    current_dir="$parent"
                fi
                ;;
            */)
                # Entrar a un subdirectorio
                # Enter a subdirectory
                current_dir="${current_dir%/}/$selection"
                # Quitar barra final si se duplico
                # Remove trailing slash if it was duplicated
                current_dir="${current_dir%/}"
                ;;
            *)
                # Se ha seleccionado un archivo
                # A file has been selected
                selected_path="${current_dir%/}/$selection"
                End_Path="$selected_path"
                return 0
                ;;
        esac
    done
}

# ------------------- Logica principal del script ------------------
# ------------------- Main script logic ------------------

# Funcion para generar el archivo .cue
# Function to generate the .cue file
Cue_Maker() {
    local Mode="$1"
    local End_Path="$2"

    # Si la ruta es un directorio
    # If the path is a directory
    if [[ -d "$End_Path" ]]; then
        dialog --clear
        dialog --title "Warning" --yesno "All existing .cue files in the directory: $End_Path will be replaced.\n\nNOTE: This will take a while depending on the number of files to generate and requires a console load. Do not touch anything after accepting until this screen updates itself.\n\nDo you want to continue?" 13 60 2>/dev/tty1
        local rc=$?

        case $rc in
            0)
                # El usuario aceptó, procesar todos los .bin
                # The user accepted, process all .bin files
                local bin_files=("$End_Path"/*.bin)
                local total_files=${#bin_files[@]} # Get the total number of files
                
                if [[ $total_files -gt 0 ]]; then
                    
                    # --- START: Progress bar block ---
                    local current_file_num=0
                    {
                        for bin_file in "${bin_files[@]}"; do
                            # Increment counter
                            ((current_file_num++))
                            
                            # Calculate percentage
                            local percent=$(( (current_file_num * 100) / total_files ))
                            
                            # --- File creation logic (same as before) ---
                            local bin_name=$(basename "$bin_file")
                            local cue_name="${bin_name%.bin}.cue"
                            local cue_path="$End_Path/$cue_name"
                            local cue_content="FILE \"$bin_name\" BINARY\n  TRACK 01 $Mode\n    INDEX 01 00:00:00"
                            echo -e "$cue_content" > "$cue_path"
                            # --- End of creation logic ---
                            
                            # Send update to dialog
                            # We use XXX as the standard delimiter for dialog
                            echo "XXX"
                            echo "$percent"
                            # This is the text for the gauge:
                            echo "Creating file $current_file_num of $total_files"
                            # Add the current filename for more info
                            echo "$cue_name"
                            echo "XXX"
                            
                        done
                    } | dialog --clear --title "Processing Directory" --gauge "Please wait..." 10 70 0 2>/dev/tty1
                    # --- END: Progress bar block ---

                    # Completion message
                    dialog --clear
                    dialog --msgbox "Successfully generated $total_files .cue files in $Mode format in the directory: $End_Path" 10 60 2>/dev/tty1
                
                else
                    dialog --clear
                    dialog --msgbox "No .bin files were found in the directory: $End_Path" 10 60 2>/dev/tty1
                fi
                ;;
            1)
                # Cancelar → volver al mismo directorio
                # Cancel → return to the same directory
                File_Selector "$End_Path"
                return
                ;;
            255)
                # ESC o Start+Select → salir del script
                # ESC or Start+Select → exit the script
                Exit_Menu
                ;;
        esac
        
    # Si la ruta es un fichero
    # If the path is a file
    elif [[ -f "$End_Path" ]]; then
        if [[ "$End_Path" == *.bin ]]; then
            local bin_name=$(basename "$End_Path")
            local cue_path="${End_Path%.bin}.cue"
            
            # Definimos el contenido del archivo .cue en una variable
            # We define the content of the .cue file in a variable
            local cue_content="FILE \"$bin_name\" BINARY\n  TRACK 01 $Mode\n    INDEX 01 00:00:00"
            
            # Escribimos el contenido en el archivo
            # We write the content to the file
            echo -e "$cue_content" > "$cue_path"
            
            dialog --clear
            dialog --msgbox "The file has been successfully generated: $cue_path" 10 60 2>/dev/tty1
        else
            dialog --clear
            dialog --msgbox "The selected file is not a .bin." 10 60 2>/dev/tty1
            # Regresar al menu de seleccion de archivo
            # Return to the file selection menu
            File_Selector "/roms"
            return
        fi
    fi
 
    # Volver al menu principal despues de la operacion
    # Return to the main menu after the operation
    End_Path=""
    Main_Menu
}

# ------------------- Joystick controls ----------------------------


# Dar permisos al joystick e iniciar gptokeyb
# Grant permissions to the joystick and start gptokeyb
sudo chmod 666 /dev/uinput

# Cargar fichero de configuracion del joystick
# Load the joystick configuration file
export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"

# Limpiar procesos del Joystick
# Clean up Joystick processes
if [[ ! -z $(pgrep -f gptokeyb) ]]; then
  pgrep -f gptokeyb | sudo xargs kill -9
fi

# Ejecutar gptokeyb asignando permiso al script.
# Execute gptokeyb assigning permission to the script.
/opt/inttools/gptokeyb -1 "$(basename "$0")" -c "/opt/inttools/keys.gptk" > /dev/null 2>&1 &

printf "\033c" > /dev/tty1
dialog --clear
trap Exit_Menu EXIT
# Mostrar el menu de seleccion de Mode
# Show the Mode selection menu
Main_Menu
}
