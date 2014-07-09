 #!/bin/bash
  # This program delete fields of the database. 
  # The sql sentences are prepared to delete strings and selectionvalues types.
  # Autor: Victor Alejo. alejo@fzi.de
  # V.2.(2012)
  
	clear
  	echo  "** Delete strings and selectionvalues fields of the database **"

	echo "*******************************************************************"
	
	function eraser() {
    clear	
    echo "Please, insert the field you want to delete of the database."
    read FIELD
    FIELD=$(echo $FIELD | tr "[:lower:]" "[:upper:]")
    
    echo "Please, insert the name of the table (example 'address0') of the field you want to delete."
    read TABLE0
    TABLE0=$(echo $TABLE0 | tr "[:lower:]" "[:upper:]")		
    TABLE=$(expr "$TABLE0" : '\(.*\).')
    
    echo "Is the field $FIELD a string(s) or a selection value(v)?. Please write 's' or 'v' "
    read TYPE
        
      case $TYPE in
        [sS] )
          delete_string
        ;;
        [vV] )
          delete_svalue
        ;;
        *)
          wrong
        ;;
      esac
	} 	
		
	function delete_string(){
	
    echo "You are going to delete the string '$FIELD' of the table '$TABLE0', are you sure?"
    echo "yes(y) or cancel(any key)"
    read Check
          
    if [ $Check == "y" ] || [ $Check == "Y" ]	# delete it
      cont=0
    then
      for t in $DBS ; do
        if  [ 
          $t == "development" -o 
          $t == "pspesslingen" -o 
          $t == "wohlfahrtswerk" -o 
          $t == "test1" -o 
          $t == "test2" -o 
          $t == "test3" -o 
          $t == "test4" -o 
          $t == "test5" -o 
          $t == "test6" -o 
          $t == "test7" -o 
          $t == "test8" -o 
          $t == "test9" -o 
          $t == "test10" 
          ]
        then
          #flag=0
          
          CheckData # Check if the field exits in the Columnseim table of the database, and it is a string type.
            
          if [ "${row[5]}" != "STRING" ] || 
            [ "${row[3]}" == "" ] || 
            [ "${row[4]}" == "" ] || 
            [ "${row[5]}" == "" ] || 
            [ "${row[4]}" != "$FIELD" ] || 
            [ "${row[3]}" != "$TABLE0" ]
          then
           
            echo "** Database '$t'. The data introduced is not correct or not exists in this database."
            echo -e "\n"
            ((cont++))
            
          else # The field exits and it is a string
            echo "Database '$t'. Field exists in the database...Ok."
            echo "Deleting the field..."
            
            D_T=`date +%Y%m%d`   

            mysql -u root -p$PS -D $t -e 
              "select * FROM SYSCOLUMNSEIM WHERE TABLENAME LIKE '$TABLE0' 
              AND COLNAME LIKE '$FIELD' 
              AND DICTIONARYKEY LIKE '$TABLE.$FIELD';" ls -al 2>&1 | tee -a eraser.$D_T.log

            CheckData 
              
            if [ "${row[4]}" == "" ] # The column was deleted
            then
              echo "** Database '$t' *********************** deleting field....done"
            else
              echo "** There were errors in the execution. Please, check the information of the database "
            fi	
          fi

        else
          echo "Database '$t'. Does not have changes"
        fi
      done

      terminator
      again
      
    else
      again
    fi
	}
		
	function delete_svalue() {

    echo "You are going to delete the selection value '$FIELD' of the table '$TABLE0', are you sure?"
    echo "yes(y) or cancel(any key)"
    read Check		
    
    if [ $Check == "y" ] || [ $Check == "Y" ] # delete the selection value
    then
      cont=0

      for t in $DBS ; do
        if [ 
          $t == "development" -o
          $t == "pspesslingen" -o 
          $t == "wohlfahrtswerk" -o 
          $t == "test1" -o 
          $t == "test2" -o 
          $t == "test3" -o 
          $t == "test4" -o 
          $t == "test5"	-o 
          $t == "test6" -o 
          $t == "test7" -o 
          $t == "test8" -o 
          $t == "test9" -o 
          $t == "test10" 
          ]
        then	
          
          CheckData # Check if the field exits in the Columnseim table of the database, and it is a string type.
              
          if [ "${row[5]}" != "SELECTIONVALUELIST" ] || 
            [ "${row[3]}" == "" ] || 
            [ "${row[4]}" == "" ] || 
            [ "${row[5]}" == "" ] || 
            [ "${row[4]}" != "$FIELD" ] || 
            [ "${row[3]}" != "$TABLE0" ]
          then
            echo "** Database '$t'. The data introduced is not correct or not exists in this database."
            echo -e "\n"
            ((cont++))
            
          else	
            echo "Database '$t'. Field exists in the database '$t'...Ok."
            echo "Deleting the field..."
            
            D_T=`date +%Y%m%d`
            mysql -u root -p$PS -D $t -e 
              "DELETE FROM SELECTIONVALUESRELATION WHERE COLNAME LIKE '$FIELD' 
              AND TYPE LIKE '$TABLE';" 1>&2 | tee -a eraser.$D_T.log

            mysql -u root -p$PS -D $t -e 
              "DELETE FROM SELECTIONVALUES WHERE COLNAME LIKE '$FIELD' AND 
              DICTIONARYKEY LIKE '$TABLE.$FIELD%' AND 
              TYPE LIKE '$TABLE';" 2>&1 | tee -a eraser.$D_T.log

            mysql -u root -p$PS -D $t -e 
              "DELETE FROM SYSCOLUMNSEIM WHERE TABLENAME LIKE '$TABLE0' AND 
              COLNAME LIKE '$FIELD';" 2>&1 | tee -a eraser.$D_T.log

            mysql -u root -p$PS -D $t -e "ALTER TABLE $TABLE0 DROP $FIELD;" 1>&2 | tee -a eraser.$D_T.log
                                
            CheckData 
            
            if [ "${row[4]}" == "" ] # The column was deleted
            then
              echo -e "** Database '$t' *********************** deleting field....done \n"
            else
              echo "** There were errors in the execution. Please, check the information of the database"
            fi
          
          fi			
        else
          echo "Database '$t'. Does not have changes"
        fi 
      done

      terminator
      again
    else
      again
    fi		
	}
		
	function again() {
	  echo "Press any key to continue deleting fields, or (e) to exit"
	  read continue
		
		if [ $continue == "e" ]
		then
			exit 1
		else
			eraser
		fi
	} 
	
	function wrong(){
	  echo "Please, select the correct option. Press any key to continue or (e) to exit."
	  read continue
		if [ $continue == "e" ]
		then
			exit 2
		else
			clear
			eraser
		fi
		clear
	}
	
	function CheckData(){
    #Check if the field is a string value
    
    check_string=$(mysql -u root -p$PS -D $t -e "SELECT TABLENAME,COLNAME,COLTYPE FROM SYSCOLUMNSEIM WHERE COLNAME LIKE '$FIELD' AND TABLENAME LIKE '$TABLE0';")
    row=( $( for i in $check_string ; do echo $i ; done ) )					
	}
	
	function terminator(){
	
    if [ $cont -eq 13 ]; then 
	    echo "Nothing was deleted in any database."
	  else
	
		  echo "
		              _______
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
	"
	
	    echo -e "** You shoud update the database and restart Tomcat Server.\n"
	  fi
	}
	
		
if [ $(whoami) != "root" ] ; then
  echo "You should be root to run this script."
	else
		while [ ls $DBS 2>/dev/null != 0 ]; do
			echo "Please, enter the password to connect with the databases"
			read -s PS
			DBS=`mysql -u root -p$PS -e "show databases"`
		done
		
	clear
	eraser
fi	
