1. đẩy file lên share file trung gian
 smbclient //10.1.35.36/Public/ -U ncb-bank/thuongtv.os -c "lcd /home/ftpuser/ftp; cd /; put NCB_20240306.zip"
2. Lấy share file trung gian về máy chủ
   smbclient //10.1.35.36/Public/ -U ncb-bank/thuongtv.os -c "lcd /setup; cd /; get NCB_20240306.zip"

3. Deploy
   5.1	Hệ thống Application Server (10.1.62.55)
- Bước 1: backup file ROOT.war vào thư mục /opt/tomcat-icredit/yyyymmdd/
Lênh: sudo cp –R /opt/tomcat-icredit/webapps/ROOT.war  /opt/tomcat-icredit/yyyymmdd/
- Bước 2: Copy file application.properties vào thư mục /opt/tomcat-icredit
Lệnh: sudo cp –R /opt/tomcat-icredit/webapps/ROOT/WEB-INF/classes/application.properties opt/tomcat-icredit
- Bước 3: Xóa file ROOT.war
Lệnh: sudo rm –rf  /opt/tomcat-icredit/webapps/ROOT.war
- Bước 4: Copy file ROOT.war vào thư mục /opt/tomcat-icredit/webapps
- Bước 5: Copy file application.properties vào thư mục /opt/tomcat-icredit/webapps/ROOT/WEB-INF/classes
Lệnh: sudo cp –R /opt/tomcat-icredit/ application.properties  /opt/tomcat-icredit/webapps/ROOT/WEB-INF/classes
- Bước 6: vào thư mục bin tomcat để restart hệ thống.
Lệnh: cd /opt/tomcat-icredit/bin/
 Sudo ./shutdown.sh
 Sudo ./startup.sh

* Deploy UI
- Bước 1: backup thư mục UI.
Lệnh sudo mv –R /u01/NEWUI/vn/ /u01/NEWUI/vn.bkyyyymmdd
- Bước 2: Copy thư mục vn vào đường dẫn /u01/NEWUI/
- Bước 3: sudo chmod –R 755 /u01/NEWUI/

5.2	Hệ thống Service Integration (10.1.62.56)
a,	Core service
- Cập nhật file jar nếu có :
Bước 1: Backup file jar
sudo mv /u01/fdp-core-service/fdp-core-service-1.0.0.jar /u01/fdp-core-service/ fdp-core-service-1.0.0.jar.bkyyyymmdd
Bước 2: Copy file fdp-core-service-1.0.0.jar vào thư mục /u01/fdp-core-service/
- Cập nhật file properties nếu có:
Bước 1: Backup file properties
sudo mv /u01/config/FdpCoreConfig.properties /u01/config/FdpCoreConfig.properties.bkyyyymmdd
	Bước 2: Copy file FdpCoreConfig.properties  vào thư mục                  
/u01/config/ FdpCoreConfig.properties
- Build lại service: sudo sh /u01/buildCore.sh
  
b, Bank service
  - Cập nhật file jar nếu có :
Bước 1: Backup file jar
sudo mv /u01/cis-bank-service/cis-bank-service-1.0.0.jar /u01/cis-bank-service/ cis-bank-service-1.0.0.jar.bkyyyymmdd
Bước 2: Copy file cis-bank-service-1.0.0.jar vào thư mục /u01/cis-bank-service/
- Cập nhật file properties nếu có:
Bước 1: Backup file properties
sudo mv /u01/config/FdpBankConfig.properties /u01/config/FdpBankConfig.properties.bkyyyymmdd
	Bước 2: Copy file FdpBankConfig.properties  vào thư mục                  
/u01/config/FdpBankConfig.properties
- Build lại service: sudo sh /u01/buildBank.sh

c,	ICredit service
  - Cập nhật file jar nếu có :
Bước 1: Backup file jar
sudo mv /u01/fdp-icredit-service/fdp-icredit-service-1.0.0.jar /u01/fdp-icredit-service/fdp-icredit-service-1.0.0.jar.bkyyyymmdd
Bước 2: Copy file fdp-icredit-service-1.0.0.jar vào thư mục /u01/fdp-core-service/
- Cập nhật file properties nếu có:
Bước 1: Backup file properties
sudo mv /u01/config/FdpIcreditConfig.properties /u01/config/FdpIcreditConfig.properties.bkyyyymmdd
	Bước 2: Copy file FdpIcreditConfig.properties vào thư mục                  
/u01/config/ FdpIcreditConfig.properties
- Build lại service: sudo sh /u01/buildicredit.sh

d,	CIC service
  - Cập nhật file jar nếu có :
Bước 1: Backup file jar
sudo mv /u01/fdp-cic-service/fdp-cic-service-1.0.0.jar /u01/fdp-cic-service/fdp-cic-service-1.0.0.jar.bkyyyymmdd
Bước 2: Copy file fdp-cic-service-1.0.0.jar vào thư mục /u01/fdp-cic-service/
- Cập nhật file properties nếu có:
Bước 1: Backup file properties
sudo mv /u01/config/FdpCICConfig.properties /u01/config/FdpCICConfig.properties.bkyyyymmdd
	Bước 2: Copy file FdpCICConfig.properties vào thư mục                  
/u01/config/FdpCICConfig.properties
- Build lại service: sudo sh /u01/buildiCIC.sh


e,	PCB service
 - Cập nhật file jar nếu có :
Bước 1: Backup file jar
sudo mv /u01/fdp-pcb-service/fdp-pcb-service-1.0.0.jar /u01/fdp-pcb-service/fdp-pcb-service-1.0.0.jar.bkyyyymmdd
Bước 2: Copy file fdp-pcb-service-1.0.0.jar vào thư mục /u01/fdp-pcb-service/
- Cập nhật file properties nếu có:
Bước 1: Backup file properties
sudo mv /u01/config/FdpPCBConfig.properties /u01/config/FdpPCBConfig.properties.bkyyyymmdd
	Bước 2: Copy file FdpPCBConfig.properties  vào thư mục                  
/u01/config/FdpPCBConfig.properties
- Build lại service: sudo sh /u01/buildiPCB.sh
