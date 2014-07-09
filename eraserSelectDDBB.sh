 #!/bin/bash
  # This program delete fields of the database. 
  # The sql sentences are prepared to delete strings and selectionvalues types.
  # Autor: Victor Alejo. alejo@fzi.de
  # V.4.(2012)
  # New Features: - This version let the user choose what database want to use.
  #				  - New functions: *showSelectDataBases. Check and show the ddbb in the machine and save the selection of the user.
  #								   *saveDB.Link with the showSelectDataBases function and control the repetion of the ddbb selected.  		  
  
function eraser(){

	if [ "$check" == "y" ] || [ "$check" == "Y" ]	# delete it
	then
		if 
      [ $TYPE == "STRING" -o 
        $TYPE == "INT" -o 
        $TYPE == "BOOLEAN" -o 
        $TYPE == "DATETIME" 
      ]
		then
			deleteSimpleField
		else

			if [ $TYPE=="SELECTIONVALUELIST" ]
			then
				deleteSelectionValue
			fi
		fi
    
	else
		echo "Canceled. Press any key to continue or (e) to exit."
		read continue

		if [ $continue == "e" ]
		then
			exit 1
		else
			clear
			saveDB
		fi
		clear
	fi

	} 	

	function deleteSimpleField(){
    cont=0
    contFor=0
    D_T=`date +%Y%m%d`  
    LOG=eraser.$D_T.log

    while [ $c -gt 0 -o $c -eq 0 ]; do
      t=${selectedDB[c]}
      mysql -u root -p$PS -D $t -e 
        "DELETE FROM SYSCOLUMNSEIM WHERE TABLENAME LIKE '$TABLE0' AND 
        COLNAME LIKE '$FIELD' AND 
        DICTIONARYKEY LIKE '$TABLE.$FIELD';" | tee -a $LOG 

      mysql -u root -p$PS -D $t -e "ALTER TABLE $TABLE0 DROP $FIELD;" | tee -a $LOG
    
      #CheckData # Check if the data was deleted
      delete=1	
      checkData
        if [ "${row[4]}" == "" ] # The column was deleted
        then
          echo "**	Database '$t' *********************** deleting field....done"
        else
          echo "**	Database '$t'... There were errors in the execution. Please, check the data of the database "
          ((cont++))						
        fi	
        ((contFor++))

      ((c--))
    done

    terminator
    again	
	}
		
	function deleteSelectionValue(){
    cont=0
    contFor=0	
    D_T=`date +%Y%m%d`  
    LOG=eraser.$D_T.log
    
    while [ $c -gt 0 -o $c -eq 0 ]; do
      t=${selectedDB[c]}				
      mysql -u root -p$PS -D $t -e 
        "DELETE FROM SELECTIONVALUESRELATION WHERE COLNAME LIKE '$FIELD' AND 
      TYPE LIKE '$TABLE';"  | tee -a $LOG

      mysql -u root -p$PS -D $t -e 
        "DELETE FROM SELECTIONVALUES WHERE COLNAME LIKE '$FIELD' AND 
        DICTIONARYKEY LIKE '$TABLE.$FIELD%' AND 
        TYPE LIKE '$TABLE';" | tee -a $LOG
        
      mysql -u root -p$PS -D $t -e 
        "DELETE FROM SYSCOLUMNSEIM WHERE TABLENAME LIKE '$TABLE0' AND 
        COLNAME LIKE '$FIELD';" | tee -a $LOG

      mysql -u root -p$PS -D $t -e 
        "ALTER TABLE $TABLE0 DROP $FIELD;" | tee -a $LOG
    
      #CheckData. Check if the data was deleted after the sql scripts were executed.
      delete=1	
      checkData

      if [ "${row[4]}" == "" ] # The column was deleted
      then
        echo "**	Database '$t' *********************** deleting field....done"
      else
        echo "**	Database '$t'... There were errors in the execution.The name of the table has to be like 'address0'. Please, check the data introduced "
        ((cont++))						
      fi	
      ((contFor++))

      ((c--))
    done

    terminator
    again											
	}
				
	function checkData(){
    if [ $delete -eq 0 ]
    then
      echo "The selected databases are: "
      echo "-> ${selectedDB[*]} "			
      echo "Please, insert the field you want to delete of the database."
      read FIELD
      FIELD=$(echo $FIELD | tr "[:lower:]" "[:upper:]")
      echo "Please, insert the name of the table (example 'address0') of the field you want to delete."
      read TABLE0
      TABLE0=$(echo $TABLE0 | tr "[:lower:]" "[:upper:]")		
      TABLE=$(expr "$TABLE0" : '\(.*\).')
      echo -e "\n"
      
      #Check the field in one of the database, in this case 'the first of the array'
      
      database=${selectedDB[0]}  # Take the first database to check the data.
      checkType=$(mysql -u root -p$PS -D $database -e "SELECT TABLENAME,COLNAME,COLTYPE FROM SYSCOLUMNSEIM WHERE COLNAME LIKE '$FIELD' AND TABLENAME LIKE '$TABLE0';")
      row=( $( for i in $checkType ; do echo $i ; done ) )
      
      # Check if the data exits
      if  [ "${row[5]}" == "" ] || 
        [ "${row[3]}" == "" ] || 
        [ "${row[4]}" == "" ] || 
        [ "${row[5]}" == "" ] || 
        [ "${row[4]}" != "$FIELD" ] || 
        [ "${row[3]}" != "$TABLE0" ] # Don´t exists
        
      then
        echo "** The data introduced not exists in the databases."
        echo "	Nothing was deleted in any database."
        echo -e "\n"
        
        again
      else
        TYPE=${row[5]} 
        
        echo "You are going to delete the $TYPE field '$FIELD', of the table '$TABLE0'"
        echo "are you sure?, yes(y) or cancel(any key)"
        read check
        
        # Recuperate the value of the number of elements			
        c=$elements
        eraser
      fi
    else
      # delete=1. The scripts have been executed and check if the data was deleted.

      database=${selectedDB[c]}  # Value in that moment
      checkType=$(mysql -u root -p$PS -D $database -e 
        "SELECT TABLENAME,COLNAME,COLTYPE FROM SYSCOLUMNSEIM WHERE COLNAME LIKE '$FIELD' AND 
        TABLENAME LIKE '$TABLE0';")
      row=( $( for i in $checkType ; do echo $i ; done ) )	
    fi
    delete=0
	}

	function saveDB(){
		if [ $anotherTime -eq 1 ]
		then
			echo "Press any key to continuing with the same databases "
			echo "or (n) to use another databases."
			#reply=""
			read reply
			if [ "$reply" == "n" ] || [ "$reply" == "N" ] 
			#|| [ -z "$reply" ]
			then
				showSelectDataBases
			else
				checkData
			fi
		else
			showSelectDataBases
		fi
	}
		
	function showSelectDataBases(){
	  # * Show the databases

    echo " ** Those are the databases in this machine: "
    echo -e "\n"
    a=0
    for ddbb in $DBS 
      do	
        machineDB[a]=$ddbb	
        echo "[$a]-${machineDB[a]}"
        ((a++))
    done

    echo -e "\n"
    # rest the last iteration
    ((a--))
    
    # * Choose what databases
    
    echo "Please, select between spaces the number of the databases you want to use. Example'(0 2 5)'"
    DDBB=""
    read DDBB

    if [ -z "$DDBB" ];then #echo "Select at less one database"
      clear
      showSelectDataBases
    else
      c=0
      
      # Empty the whole array
      unset selectedDB[@]
      for selectedNumber in $DDBB
       do
        if [ $selectedNumber -lt 0 ] || 
          [ $selectedNumber -gt $a ] || 
          [[ $selectedNumber != [0-9]* ]] #! [[ $selectedNumber =~ ^[0-9]+$ ]]
                                          #|| [[ $selectedNumber = *[[:digit:]]* ]]
        then
          clear
          echo "Please, insert a correct value"
          showSelectDataBases
        else
          selectedDB[c]=${machineDB[selectedNumber]}	
          ((c++))
        fi
      done

      #Rest the last iteration
      ((c--))
      # Save the value of 'c' (number of elements)
      elements=$c
      checkData
    fi
	}
	
	function again(){
    echo "Press any key to continue deleting fields, or (e) to exit"
    #initialization go
    #go="go"
    #anotherTime=0
    read go
    
    if [ $go == "e" ]
    then
      exit 1
    else
      clear
      anotherTime=1			
      saveDB
    fi
	} 
	
	function terminator(){

	if [ $cont -eq $contFor ]
	then	
		echo -e "\n"
		echo "	Nothing was deleted in any database."
		echo -e "\n"
	else
		echo "
		              
                     <((((((\\\\\\
                     /      . }\\
                     ;--..--._|}
  (\\                 '--/\\--'  )
   \\\\                | '-'  :'|
    \\\\               . -==- .-|
     \\\\               \\.__.'   \\--._
     [\\\\          __.--|       //  _/'--.
     \\ \\\\       .'-._ ('-----'/ __/      \\
      \\ \\\\     /   __>|      | '--.       |
       \\ \\\\   |   \\   |     /    /       /
        \\ '\\ /     \\  |     |  _/        /
         \\  \\       \\ |     | /         /
          \\  \\      \\        /		  	
	            (alejo@fzi.de)2012"
		echo -e "\n"			   
		echo -e "** You shoud restart Tomcat Server.\n"
	
	fi
	}
		
	
	clear
  	echo  "                ** ERASER Script ** "
	echo  "	** Delete fields of the database **"

	echo "******************************************************************"
	  if [ $(whoami) != "root" ] ; then
		  echo "You should be root to run this script."
		else
			while [ ls $DBS 2>/dev/null != 0 ]; do
				echo "Please, enter the password to connect with the databases"
				read -s PS
				DBS=`mysql -u root -p$PS -e "show databases"`
			done
      
		echo "Password OK."
		echo -e "\n"
			
	fi
	  anotherTime=0
	  delete=0
	  saveDB
