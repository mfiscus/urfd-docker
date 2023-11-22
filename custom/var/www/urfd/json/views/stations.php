<?php

$payload = array();


/*** Add stations to payload ***/
for ($i=0;$i<$Reflector->StationCount();$i++) {
	
    // craft payload array
    $payload['stations'][] = array(
        'callsign'       => $Reflector->Stations[$i]->GetCallSign(),
        'callsignsuffix' => $Reflector->Stations[$i]->GetSuffix(),
        'vianode'        => $Reflector->Stations[$i]->GetVia(),
        'onmodule'       => $Reflector->Stations[$i]->GetModule(),
        'lastheard'      => date('c', $Reflector->Stations[$i]->GetLastHeardTime())
    );

    list ($CountryCode, $Country) = $Reflector->GetFlag($Reflector->Stations[$i]->GetCallSign());

    $payload['stations']['country'][] = array (
        'country'     => $Country,
        'countrycode' => $CountryCode
    );

}


// json encode payload array
$records = json_encode($payload);

echo $records;

?>