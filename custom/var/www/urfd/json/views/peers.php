<?php

/*** Add links to payload ***/
for ($i=0;$i<$Reflector->PeerCount();$i++) {

    $payload = array(
        'callsign'      => $Reflector->Peers[$i]->GetCallSign(),
        'ip'            => $Reflector->Peers[$i]->GetIP(),
        'linkedmodule'  => $Reflector->Peers[$i]->GetLinkedModule(),
        'protocol'      => $Reflector->Peers[$i]->GetProtocol(),
        'connecttime'   => date('c', $Reflector->Peers[$i]->GetConnectTime()),
        'lastheardtime' => date('c', $Reflector->Peers[$i]->GetLastHeardTime())
    );

}


// json encode payload array
$records = json_encode($payload);

echo $records;

?>