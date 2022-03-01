// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library dataStructure{

    struct Company{
        address CompanyAddress;
        string companyName;
        bool exists   ;

    }

    struct CompanyOffice{

        string headOfficeName;
        uint companyIndex;
        bool exists  ;
    }

    struct Iotdata{
       uint8 temp;
       uint8 humidity;
       string timestamp;
       string company;
       bytes hashIpfs;
       uint device;
       string mac;
       bool exists  ;

    }

    struct Device{
        string name;
        uint companyOfficeIndex;
        bool exists  ;
        string deviceCode;
    }

    struct Certificate{
        uint name;
        address company;
        bool exists  ;
    }

}

contract owned {


    event Received(address, uint);


    constructor() { owner = payable(msg.sender); }
    address payable owner;

     // This contract only defines a modifier but does not use
    // it: it will be used in derived contracts.
    // The function body is inserted where the special symbol
    // `_;` in the definition of a modifier appears.
    // This means that if the owner calls this function, the
    // function is executed and otherwise, an exception is
    // thrown.
    // questo modificatore si può applicare alle funzio0ni e permette
    //di decreate se il chiamate è il creatore del contratto
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
     receive() external payable { 

         emit Received(msg.sender, msg.value);
     }

    fallback() external payable {}


}

contract Destructible is owned {

    function destroy() public onlyOwner {
            selfdestruct(owner);
    }
}

contract Generator is Destructible{

    event CreateCompany(string name,uint companyId);
    event CreateOffice (string name, uint companycode,uint companyOfficecode);
    event CreateContract(address contractAddress,uint hi ,uint deviceid);
    event CreateDevice(uint officeIndex,string name, string deviceCode);
    event AvgDeviceTemps(uint avg,uint items);
 

    event CompanyAdded(uint indexed id, string name);

    //il mapping sarebbe sensato se si crea un contratto per ogni company
    //mapping(int => iotdata) public iotentries;   
    //dataStructure.Iotdata[] public iotentries;
    //mapping(address=>dataStructure.Company) public companies;
    //mapping(address=>dataStructure.CompanyOffice) public companiesHeadOffice;
    //mapping(uint8 =>dataStructure.Device) public devices;

    dataStructure.Company[] public companies;
    dataStructure.CompanyOffice[] public companiesHeadOffice;
    dataStructure.Device[] public devices;


    mapping(address => dataStructure.Certificate) public certificates;
    mapping(uint =>  address) public iotDataContainer;
   
 
    
    /*
    RETURN COMPANY ARRAY
    */
    function getCompanies() public view onlyOwner returns(dataStructure.Company[] memory){

        return companies;
    }

    function getHeadOffices() public view onlyOwner returns(dataStructure.CompanyOffice[] memory){
        
        return companiesHeadOffice;
    }

    function getDevices() public view onlyOwner returns(dataStructure.Device[] memory){
        
        return devices;
    }

     function getDeviceTemps(uint deviceId) public view onlyOwner returns(dataStructure.Iotdata[] memory){
    
         //return alla arry about devices  
          Iot entryBlockContract = Iot(payable(iotDataContainer[deviceId])); 
          return  entryBlockContract.geTemps();
         /*  (avg,entry) = entryBlockContract.calculateAvgTemp();
             emit AvgDeviceTemps(avg,entry);
            return  (avg,entry);*/

    
    }

    /*
    INSERT COMPANY
    */
    function setCompany(string memory name) public onlyOwner returns(uint){
  
        dataStructure.Company memory company ;
        company.companyName = name;
        company.exists = true;
        companies.push(company);

        emit CreateCompany( name, companies.length -1);
        
        return companies.length -1;
        
    }

    /*
    INSERT HEAD OFFICE
    */
    function setHeadOffice(string memory hoName,uint companyId) public onlyOwner returns(uint){

        require(companies[companyId].exists, "Company doesn't exist");

        dataStructure.CompanyOffice memory co ;

        co.headOfficeName = hoName;
        co.companyIndex = companyId;
        co.exists = true;

        companiesHeadOffice.push(co);
        //return the index
        emit CreateOffice(hoName , companyId , companiesHeadOffice.length -1);
        return companiesHeadOffice.length -1;

    }
     
    /*
    INSERT DEVICE AND CREATE CONTRACT DATA REPOSITORY
    */
    function setDevice(uint officeIndex,string memory name,string memory deviceCode) public onlyOwner returns(uint){

        require(companiesHeadOffice[officeIndex].exists, "Office doesn't exist");

        dataStructure.Device memory d ;
        d.exists = true;
        d.name = name;
        d.companyOfficeIndex  = officeIndex; 
        d.deviceCode = deviceCode;

        devices.push(d);

        uint l = devices.length -1;


        emit CreateDevice(officeIndex, name, deviceCode);
        //creo un iotconteiner per ogni dispositivo agganciato, + si più costoso ma a grana fine?più costoso più contratti o meno contratti?
        iotDataContainer[l] = address(createIotContainer(officeIndex,companiesHeadOffice[officeIndex].companyIndex,l,deviceCode));

        //return the index
        return l;

    }

    /*
    create new container, only if company and office exists
    */
    function createIotContainer(uint ho,uint cc ,uint deviceid ,string memory devicemac ) private onlyOwner returns(address addres){


        require(companiesHeadOffice[ho].exists, "Office doesn't exist");
        require(companies[cc].exists, "Company doesn't exist");

        Iot iotd = new Iot(owner,ho,cc,deviceid,devicemac);
       

        emit CreateContract(address(iotd), ho ,deviceid);


//verifica questa cosa 
       iotDataContainer[deviceid] = address(iotd);
        //register contract created into map or array

        return address(iotd);//new Iot(owner,ho,cc,deviceid);//
    }
    
    /*
    
    SET ENTRY IN HO SMART CONTRACT PASSING DEVICE ID 

    */
    function setEntry(uint8 temp,uint8 humidity,string memory timestamp,string memory company,uint deviceId,string memory mac) public onlyOwner{
    
            Iot entryBlockContract = Iot(payable(iotDataContainer[deviceId]));//Iot(address(iotDataContainer[deviceId]));
            entryBlockContract.setEntry(temp,humidity,timestamp,company,deviceId,mac)  ;
  
    }
    /*
    GET DEVICE AVG TEMPS
    */
    function getAvgTemps(uint deviceId) public onlyOwner returns(uint avg,uint entry){
    
            Iot entryBlockContract = Iot(payable(iotDataContainer[deviceId]));//Iot(address(iotDataContainer[deviceId]));
            (avg,entry) = entryBlockContract.calculateAvgTemp();
             emit AvgDeviceTemps(avg,entry);
            return  (avg,entry);

    
    }



/*
    function getAvgCompanyTemps(uint companyId) public onlyOwner returns(uint avg){ 

        //ciclare gli uffici delle company e beccare 
        //i vary edevice per head office
         for(uint i;i <= iotentries.length - 1;i++){
            temps +=iotentries[i].temp;
       }

       
        uint  temps;
       for(uint i;i <= iotentries.length - 1;i++){
            temps +=iotentries[i].temp;
       }
       uint avgtemp = temps/iotentries.length;
       emit avgTemps(avgtemp,iotentries.length);
       return avgtemp;


    }
*/


}
//singolo contratto deployato in altro blocco di blockchain per office
contract Iot is Destructible{

    event CreateIotData(uint8 temp, uint8 humidity,string timestamp,string  company,uint device,address caller);
    event CreateContract(address ownerAddress,uint ho, uint cc,uint dId,address thisadd);
    event avgTemps(uint temp,uint numItems);

    uint public headofficeCode;
    uint public companyCode;
    uint public deviceId;
    string public mac;
    
    
    //il mapping sarebbe sensato se si crea un contratto per ogni company
    //mapping(int => iotdata) public iotentries;   
    dataStructure.Iotdata[] public iotentries;
    
    constructor(address ownerAddress,uint ho, uint cc,uint dId,string memory mac) { 
        //check for
         emit CreateContract( msg.sender, ho,  cc, dId,address(this));
         //l'ownber è il contratto che ha creato tutto, e può essere l'unici a chiamare le funzioni
         owner =  payable(msg.sender) ;
         companyCode = cc;
         headofficeCode  = ho;
         deviceId = dId;
         mac = mac;

         }


    //manca onlyOwner da verificae e valuare
    function setEntry(uint8 temp, uint8 humidity,string memory timestamp,string memory company,uint device,string memory mac) public  returns( bool state){
 
        /// require mac
        //require(device == deviceId, "Device Mistake");
 
        dataStructure.Iotdata memory id ;

        id.temp = temp;
        id.humidity = humidity;
        id.timestamp = timestamp;
        id.company = company;
        id.device = device;
        id.mac = mac ;

        iotentries.push(id);
        //check with excepetions

         emit CreateIotData( temp,  humidity, timestamp,  company, device,msg.sender);

        return true;
    }

    function calculateAvgTemp() public  returns(uint,uint ){
       
       uint  temps;
       for(uint i;i <= iotentries.length - 1;i++){
            temps +=iotentries[i].temp;
       }
       uint avgt = temps/iotentries.length;
       emit avgTemps(avgt,iotentries.length);
       return (avgt,iotentries.length);

    }
     function geTemps() public view onlyOwner returns(dataStructure.Iotdata[] memory){

        return iotentries;
    }

}
