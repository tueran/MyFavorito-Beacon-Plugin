       
var exec = require('cordova/exec');

function Beacon() {}

Beacon.prototype.addBeacon = function(success, fail, params) {
exec(success, fail, "Beacon", "addBeacon", [params || {}]);
};

Beacon.prototype.removeBeacon = function(success, fail, params) {
exec(success, fail, "Beacon", "removeBeacon", [params || {}]);
};

Beacon.prototype.setHost = function(success, fail, params) {
exec(success, fail, "Beacon", "setHost", [params || {}]);
};

Beacon.prototype.getHost = function(success, fail) {
exec(success, fail, "Beacon", "getHost", []);
};
               
Beacon.prototype.setToken = function(success, fail, params) {
exec(success, fail, "Beacon", "setToken", [params || {}]);
};
               
/*
 Params:
 NONE
 */
Beacon.prototype.getWatchedBeaconIds = function(success, fail) {
exec(success, fail, "Beacon", "getWatchedBeaconIds", []);
};



// exports
var Beacon = new Beacon();
module.exports = Beacon;
