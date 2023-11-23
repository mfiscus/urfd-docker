<?php

/*** Add stations to payload ***/
for ($i=0;$i<$Reflector->StationCount();$i++) {
	
    // craft payload array
    $payload['stations'][$i] = array(
        'callsign'       => $Reflector->Stations[$i]->GetCallSign(),
        'callsignsuffix' => $Reflector->Stations[$i]->GetSuffix(),
        'vianode'        => $Reflector->Stations[$i]->GetVia(),
        'onmodule'       => $Reflector->Stations[$i]->GetModule(),
        'lastheard'      => date('Y-m-d\TH:i:sp', $Reflector->Stations[$i]->GetLastHeardTime())
    );

    list ($CountryCode, $Country) = $Reflector->GetFlag($Reflector->Stations[$i]->GetCallSign());

    $payload['stations'][$i]['country'] = array (
        'country'     => $Country,
        'countrycode' => $CountryCode
    );

}


// json encode payload array
$records = json_encode($payload);

echo $records;

?>