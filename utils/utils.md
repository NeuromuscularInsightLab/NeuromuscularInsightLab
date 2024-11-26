# scp without password

In your home directory on the host computer, type ssh-keygen -t rsa
when ask in which directory you want to save the key, hit enter (default: .ssh/id_rsa)
when ask to enter passphrase, just hit enter (no passphrase).  

Now open another terminal and log into the remote computer and create a .ssh directory in your home directory:
mkdir -p .ssh

From the host terminal, append the public key to host computer:
cat .ssh/id_rsa.pub | ssh username@remote.stanford.edu 'cat >> .ssh/authorized_keys'
You will need to enter your remote computer password.

You can now transfer files from the host computer to a remote computer without typing password.

You may need to add +ssh-rsa to the etc/ssh/ssh_config as below:
PubkeyAcceptedKeyTypes +ssh-rsa
HostKeyAlgorithms +ssh-rsa
