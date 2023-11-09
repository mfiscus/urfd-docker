<?php
header("Access-Control-Allow-Origin: *");
header('Content-Type: application/json');

date_default_timezone_set("UTC");

if (file_exists("../../../pgs/functions.php")) require_once("../../../pgs/functions.php");
if (file_exists("../../../pgs/config.inc.php")) require_once("../../../pgs/config.inc.php");

if (!class_exists('ParseXML')) require_once("../../../pgs/class.parsexml.php");
if (!class_exists('Node')) require_once("../../../pgs/class.node.php");
if (!class_exists('xReflector')) require_once("../../../pgs/class.reflector.php");
if (!class_exists('Station')) require_once("../../../pgs/class.station.php");
if (!class_exists('Peer')) require_once("../../../pgs/class.peer.php");


$Reflector = new xReflector();
$Reflector->SetXMLFile($Service['XMLFile']);
$Reflector->SetPIDFile($Service['PIDFile']);
$Reflector->LoadXML();

$QRZ_API_SECRET = getenv('QRZ_USER') or die('QRZ_USER environment variable not set');
$QRZ_API_KEY = getenv('QRZ_PASS') or die('QRZ_PASS environment variable not set');
$URF_NUM = getenv('URFNUM');


// function to lookup callsign using qrz api
function __callsign_lookup($callsign) {

    global $QRZ_API_SECRET, $QRZ_API_KEY, $URF_NUM;

    $QRZ_API_AGENT = $URF_NUM . "v1.0";

    // url for QRZ API
    $url = "https://xml.qrz.com/xml/current/";

    // payload
    $payload = array(
        'agent'    => $QRZ_API_AGENT,
        'username' => $QRZ_API_SECRET,
        'password' => $QRZ_API_KEY,
        'callsign' => strtoupper($callsign)

    );

    // define headers
    $header = array(
        'Content-Type: multipart/form-data',
        'Accept: application/xml'

    );

    // open connection
    $ch = curl_init();
    $timeout = 60;

    //set the url and other options for curl
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, $timeout);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $header);
    curl_setopt($ch, CURLOPT_VERBOSE, true);

    // submit call and return response data.
    $result = curl_exec($ch);

    // close curl connection
    curl_close($ch);

    // decode the xml response
    $response = xml_parser_create();
    xml_parse_into_struct($response, $result, $vals, $index);
    xml_parser_free($response);

    $firstname = explode(" ", $vals['4']['value']); // strip away middle initial
    
    $callsign = strtoupper($vals['2']['value']);
    $firstname = ucwords(strtolower($firstname[0]));
    $lastname = ucwords(strtolower($vals['6']['value']));
    $city = ucwords(strtolower($vals['8']['value']));
    $state = strtoupper($vals['10']['value']);
    $country = ucwords(strtolower($vals['12']['value']));

    $data = array(
        'callsign' => $callsign,
        'fname'    => $firstname,
        'lname'    => $lastname,
        'city'     => $city,
        'state'    => $state,
        'country'  => $country

    );

    return $data;

}


// function to query local database for operator name
function __operator_lookup($callsign) {
    try {
        /*** connect to database ***/
        $dbh = new PDO("sqlite:/config/operators.db");

        $sql = "
            SELECT callsign, fname, lname, city, state, country
            FROM operators
            WHERE callsign = ?
        ";

        $stmt = $dbh->prepare($sql);
        $stmt->bindParam(1, $callsign, PDO::PARAM_STR);
        $blnSuccess = $stmt->execute();
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC); 

        if (!$blnSuccess) {
            $error = $dbh->errorInfo();
            print $error[2];

        }

    } catch(PDOException $e) {
        print $e->getMessage();

    }

    // retrieve name from local database or if missing update it with qrz api
    //if (empty($result['0']['fname']) || empty($result['0']['lname'])) {
    if (empty($result['0']['callsign'])) {
        /*** retrieve info from qrz api and store in database ***/
        $qrzrecord = __callsign_lookup($callsign);

	    /*** we don't already know the operator address so lets record it ***/
        $insert = "
            INSERT INTO operators (callsign, fname, lname, city, state, country)
            VALUES (?, ?, ?, ?, ?, ?)
        ";

        $stmt = $dbh->prepare($insert);
        $stmt->bindParam(1, $qrzrecord['callsign'], PDO::PARAM_STR);
        $stmt->bindParam(2, $qrzrecord['fname'], PDO::PARAM_STR);
        $stmt->bindParam(3, $qrzrecord['lname'], PDO::PARAM_STR);
        $stmt->bindParam(4, $qrzrecord['city'], PDO::PARAM_STR);
        $stmt->bindParam(5, $qrzrecord['state'], PDO::PARAM_STR);
        $stmt->bindParam(6, $qrzrecord['country'], PDO::PARAM_STR);
        $blnSuccess = $stmt->execute();

        if (!$blnSuccess) {
            print_r($dbh->errorInfo());
            print $error[2];

        }

        // use results from qrz api request
        $name = $qrzrecord;

    } else {
        // use results from local database
	    $name = $result['0'];

    }

    return $name;

}


/*** add reflector to payload ***/
$payload = array(
    'reflector' => array(
        'name'      => str_replace("XLX", "URF", $Reflector->GetReflectorName()),
        'author'    => $PageOptions['MetaAuthor'],
        'contact'   => $PageOptions['ContactEmail'],
        'version'   => $Reflector->GetVersion(),
        'uptime'    => FormatSeconds($Reflector->GetServiceUptime()),
        'dashboard' => $CallingHome['MyDashBoardURL'],
        'comment'   => $CallingHome['Comment'],
        'country'   => $CallingHome['Country'],
        'stations'  => $Reflector->NodeCount(),
        'peers'     => $Reflector->PeerCount()
    ),
);


/*** Add modules to payload ***/
$Modules = $Reflector->GetModules();
sort($Modules, SORT_STRING);

for ($i=0;$i<count($Modules);$i++) {
	
    $payload['reflector']['modules'][] = array(
        'name'        => $Modules[$i],
        'description' => $PageOptions['ModuleNames'][$Modules[$i]]

    );

}


/*** Add peers to payload ***/
for ($i=0;$i<$Reflector->PeerCount();$i++) {

    $payload['reflector']['linked'][] = array(
        'name'      => $Reflector->Peers[$i]->GetCallSign(),
        'connected' => date('c', $Reflector->Peers[$i]->GetConnectTime()),
        'lastheard' => date('c', $Reflector->Peers[$i]->GetLastHeardTime()),
        'protocol'  => $Reflector->Peers[$i]->GetProtocol(),
        'module'    => $Reflector->Peers[$i]->GetLinkedModule()

    );

}


/*** Add stations to payload ***/
for ($i=0;$i<$Reflector->NodeCount();$i++) {

    // get operator details
    $operator = __operator_lookup($Reflector->Nodes[$i]->GetCallSign());

    // craft payload array
    $payload['stations'][] = array(
        'id'        => $Reflector->Nodes[$i]->GetRandomID(),
        'callsign'  => $operator['callsign'],
        'fname'     => $operator['fname'],
        'lname'     => $operator['lname'],
        'city'      => $operator['city'],
        'state'     => $operator['state'],
        'country'   => $operator['country'],
        'station'   => $Reflector->Nodes[$i]->GetCallSign() . '-' . $Reflector->Nodes[$i]->GetSuffix(),
        'connected' => date('c', $Reflector->Nodes[$i]->GetConnectTime()),
        'lastheard' => date('c', $Reflector->Nodes[$i]->GetLastHeardTime()),
        'module'    => $Reflector->Nodes[$i]->GetLinkedModule(),
        'protocol'  => $Reflector->Nodes[$i]->GetProtocol()

    );

}


/*** Add Last Heard users to payload ***/
for ($i=0;$i<$Reflector->StationCount();$i++) {

    // get operator details
    $operator = __operator_lookup($Reflector->Stations[$i]->GetCallsignOnly());

    // properly format station name (replace spaces with hyphen)
    $via = preg_replace('#[ -]+#', '-', $Reflector->Stations[$i]->GetVia());
	
    // craft payload array
    $payload['operators'][] = array(
        'callsign'  => $operator['callsign'],
        'fname'     => $operator['fname'],
        'lname'     => $operator['lname'],
        'city'      => $operator['city'],
        'state'     => $operator['state'],
        'country'   => $operator['country'],
        'custom'    => $Reflector->Stations[$i]->GetSuffix(),
        'via'       => $via,
        'peer'      => $Reflector->Stations[$i]->GetPeer(),
        'lastheard' => date('c', $Reflector->Stations[$i]->GetLastHeardTime()),
        'module'    => $Reflector->Stations[$i]->GetModule()

    );

}


// json encode payload array
$records = json_encode($payload);

echo $records;