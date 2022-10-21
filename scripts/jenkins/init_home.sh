defaultUser=jenkins
user=$1
if [ -z "$user" ]
then
      echo "User not set. User will be set to $defaultUser."
      user=$defaultUser
else
      echo "User set to $user"
fi

if [ $(getent passwd $user) ] ; then
        echo user $user found. Initing home.
else
        echo Nothing to do for user $user as it doesn\'t exists
        exit
fi

cp get_admin_pw.sh /home/$user --preserve=mode
