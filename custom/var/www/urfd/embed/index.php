<?php
header("Access-Control-Allow-Origin: *");
$URL = getenv('URL') or die('URL environment variable not set');
$SSL = @getenv('SSL') or $SSL = false;
?>
<style>
.reflector {
  text-align: left;
  white-space: nowrap;
  padding: 10px;
}
</style>
<script>
const callApi = async () => {
  const api = "<?php echo ($SSL == 'true') ? 'https' : 'http'; ?>://<?=$URL ?>/api/1.0/reflector/";
  const response = await fetch(api);
  const myJson = await response.json(); //extract JSON from the http response
  var table = "<table><tr><th class=\"reflector\">Name</th><th class=\"reflector\">Station</th class=\"reflector\"><th class=\"reflector\">Last Heard</th><th class=\"reflector\">Protocol</th></tr>";
  for (var i in myJson.stations) {
    const lastheard = new Date(myJson.stations[i].lastheard);
    const options = { timeZone: "UTC", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", hour12: false, };
    const datetime = lastheard.toLocaleString("en-US", options);
    const formatteddate = datetime.replace(/,\s*/, " ");
    table += "<tr><td class=\"reflector\">" + myJson.stations[i].fname + " " + myJson.stations[i].lname[0] + "</td><td class=\"reflector\"><a href=\"https://www.qrz.com/db/" + myJson.stations[i].callsign + "\" target=\"_blank\">" + myJson.stations[i].station + "</a></td><td class=\"reflector\">" + formatteddate + "</td><td class=\"reflector\">" + myJson.stations[i].protocol.replace("DMRMmdvm", "DMR") + "</td></tr>";
  }
  table += "</table>"
  document.getElementById('reflector').innerHTML = table;
}
window.setInterval('callApi()', 10 * 1000);
callApi();
</script>
<div id="reflector"></div>
