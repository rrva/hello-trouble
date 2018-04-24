# Det brinner i java

Den här övningen går ut på att lära sig att mäta och felsöka ett prestandaproblem i en existerande applikation.

Den här övningen passar bäst att göra på en dator som kör OSX eller Linux. Windows funkar, men alla steg är inte kvalitetssäkrade.

## A. Para ihop er i lagom stora grupper, 2-3 pers

Ni kommer få ett grupp-nummer tilldelade av oss. Kom ihåg det för senare bruk.


## B. Systemet vi ska undersöka

Vi ska undersöka en servertjänst som vi kallar hello-dataloader, som exponerar lite data via GraphQL. GraphQL är ett frågespråk för att låta en klient speca vilket data (vilka fält) den vill ha från servern. 

För att bygga:

	git clone https://github.com/rrva/hello-dataloader
	cd hello-dataloader
	./gradlew repackage
	
Om allt gått bra har du nu filen _build/distributions/hello-dataloader-1.0-SNAPSHOT.{tar/zip}_	 		
	
Packa upp filen build/distributions/hello-dataloader-1.0-SNAPSHOT.{tar/zip} (för linux/mac resp windows)	
	
För att köra:

	./hello-dataloader-1.0-SNAPSHOT/bin/hello-dataloader

På windows heter startskriptet `hello-dataloader.bat`
	
Utforska appen, besök <http://localhost:8080/graphiql.html>

Nu kommer du till ett frågeverktyg som heter _GraphiQL_

Prova t.ex. graphql-queryn

```	
{
  myContent {
    all {
      id
      name
    }
  }
}
```

Eller

```
{
  myContent {
    all {
      id
      name
      genres {
        recommended {
          byline
          description
        }
      }
    }
  }
}
```	

Som du ser anger klienten lite vilka fält den vill ha och datat kan hänga ihop som en graf.

Det vi har här är ett system skrivet i Kotlin (nästan som Java), som kör på JVM:en, som servar lite dummy-data via GraphQL.

## C. Lägg på lite last och mät

Installera lasttest-verktyget siege

	brew install siege

### Kör en lastgenerator 

Här en lastgenerator som skickar 6 samtidiga graphql-frågor till vår app:

	cd src/test/resources/
	./loadtest.sh
	
Du kan avbryta testet med <kbd>CTRL</kbd>+<kbd>C</kbd>	
### Mät 

* Svarstider
* CPU-last (kolla t.ex. med `top` i Linux eller Activity Monitor på Mac)

### Frågor

* Vilka svarstider får du?
* Hur beter sig svarstiderna om du ökar antalet samtidiga klienter `-c 6` i siege

### Var ligger flaskhalsarna för att kunna öka flödet?

#### Kör en profilerare som mäter var CPU-tid spenderas

För att mäta var tid går åt, kan vi köra den gamla trotjänaren VisualVM (`jvisualvm`). Detta måste du göra medans lastgeneratorn kör, eller hur?

1. Starta VisualVM t.ex. med `jvisualvm`
2. Koppla upp dig mot appen under sektionen Local (den som kör **se.rrva.App**) genom att dubbelklicka. Ha tålamod, det tar lång tid.
3. Välj fliken **Sampler**
4. Tryck på knappen **CPU** under Sample
5. Vänta 30 sekunder
6. Ta nu ett snapshot genom att klicka på **Snapshot**
7. Längst ner finns nu knappen **Hot spots**

### Frågor

* Vad ser vi hittills?
* Några ledtrådar om var appen kan ha prestandaproblem?

Kanske har du redan nu hittat problemen. I så fall bra! 



## D. Skapa en testmiljö för att generera Flame Graphs

Nu ska vi undersöka ett alternativt sätt att mäta och visualisera prestanda som kallas **Flame Graphs**. Flame graphs är helt enkelt en graf som visar metoderna i ditt program som olika breda staplar beroende på hur stor andel av den totala tiden som programmet spenderar där, och på höjden är de ordnade efter stacken, dvs `metodA()` ropar på `metodB()` som ropar på `methodC()`. För att göra det är det bäst vi kör i en känd testmiljö och under Linux (andra sätt finns att rita dessa flame graphs men där får vi bra resultat för denna övning).

### Installera Amazon AWS EC2 commandline tools

#### Instruktioner

Det finns många sätt att installera aws cli på, se här (eller hoppa till nästa punkt om du har Mac):

<https://docs.aws.amazon.com/cli/latest/userguide/installing.html>


#### Sammanfattning instruktioner för Mac, annars läs länken ovan

##### Installera pip

Kolla om du har pip installerat

	pip --version
	
Om inte, installera

	curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
	sudo python get-pip.py

##### Installera aws cli

	pip install awscli --upgrade --user

##### Lägg till python-skript-katalog till din sökväg

	export PATH=$PATH:~/Library/Python/2.7/bin
	
Om du vill, gör PATH-inställingen permanent

	echo 'export PATH=$PATH:~/Library/Python/2.7/bin' >> ~/.bashrc
	
	
#### Konfigurera säkerhetsnyckel för aws-cli

Om du har använt aws-cli förut och inte vill bli av med dina inställningar
kan du göra en backup:

    mv ~/.aws ~/.aws.backup

På slutet av övningen kan du då återställa dina inställningar:

    rm -rf ~/.aws
    mv ~/.aws.backup ~/.aws

Använd inte ett eget AWS-konto, saker i tutorialen är skapade utifrån mitt AWS-konto :)

Paxa en användare från <https://docs.google.com/spreadsheets/d/15N-IyO5bFvOB5-3zg_XE7giiHOw9B0JJ6gZJLNAxqd0/edit?usp=sharing>, välj en användare `tprgX` som svarar mot ditt gruppnummer.

Konfigurera aws cli med nycklar från ovan, ange `eu-central-1` som default region.

	aws configure

Kontrollera att din konfiguration i *~/.aws/config* ser ut så här:

	[default]
	region = eu-central-1
	

## TA EN PAUS KANSKE?

	 		
### Starta en EC2-instans

Vi kommer att begära att en instans startas enligt vad som står i filen ec2.json som ligger i *hello-trouble*-git-repot.

Du kan klona ut det också:

	https://github.com/rrva/hello-trouble.git

Begär att få köra en Amazon EC2-instans till spot-marknads-pris, som kommer stängas ner automatiskt efter 2 timmar.

	cd hello-trouble
	aws ec2 request-spot-instances --block-duration-minutes 120 --launch-specification file://ec2.json
	
#### Hitta ip-address för din EC2-instans

	aws ec2 describe-instances --query "Reservations[*].Instances[*].PublicIpAddress" --output=text	
Om detta inte gått bra, kanske din spot instance request slagit fel. prova då med: 

	aws ec2 describe-spot-instance-requests
	
Om spot instance request av någon anledning inte funkar, skapa en vanlig instans utan spot-marknadspris:

	aws ec2 run-instances --cli-input-json file://ec2.json
		
	
#### Konfigurera ssh

För bekvämlighet, kan vi konfigurera ssh-nyckeln som krävs för att logga in och spara den ip-address du fick under ett kortfattat namn, vi väljer att kalla maskinen för aliaset `ec2`. På så sätt blir alla `ssh`-kommandon vi kommer köra enklare.

Kopiera tprg-key.pem från google doc:et och spara som `~/.ssh/tprg-key.pem`
	
Se till att filen bara är läsbar av din användare:
	
	chmod 600 ~/.ssh/tprg-key.pem
	
Lägg till nedanstående i filen **~/.ssh/config** med din favvo-editor:	
	
```
Host ec2
    HostName <ip-adress för din instans>
    User ec2-user
    IdentityFile ~/.ssh/tprg-key.pem
    IdentitiesOnly yes
    StrictHostKeyChecking no
```

På windows 10 följ <https://winaero.com/blog/enable-openssh-client-windows-10/>

#### Kontrollera inloggning via ssh

	ssh ec2
	
Om allt gått bra får du en bash-prompt på din nya instans. 

Kontrollera att t.ex. `siege` är installerat genom att försöka köra `siege` (om du är för het på gröten, vänta en minut, kanske setup-skriptet fortfarande kör). 

#### Starta hello-dataloader på ec2

Kopiera koden dit. Från katalogen med hello-dataloader-repot:

	scp build/distributions/hello-dataloader-1.0-SNAPSHOT.tar ec2:

Starta appen

	ssh ec2
	tar xf hello-dataloader-1.0-SNAPSHOT.tar
	./hello-dataloader-1.0-SNAPSHOT/bin/hello-dataloader

I en annan terminal, kopiera upp lasttest-skripten till ec2 och starta

	scp src/test/resources/loadtest* ec2:
	ssh ec2
	./loadtest.sh
	
	
I en tredje terminal, undersök systemets last med verktyget *top*

	ssh ec2
	top
				
	
### Frågor

1. Hur beter sig systemets svarstider?
2. Hur ser maskinens totala last ut?

Om du ökar antalet samtidiga anrop i lasttestet (ändra `-c6` till `-c60`)
Du kan använda `nano` eller `vi` som editor i på ec2-maskinen.

1. Hur beter sig svarstiderna nu?
2. Hur beter sig systemets last?
3. Vad säger detta om flaskhalsen?


### Rita en flame graph

Nu till det mest spännande, efter mycket om och men! Vi ska rita en flame graph över systemets prestanda.

I en fjärde terminal, logga in och fånga en flame graph medan lasttestet kör. Här kör vi som root, övningen blev upplagd så men egentligen är det inte nödvändigt.

	ssh ec2
	sudo -i
	
Vi ska nu spela in vilka metodanrop som appen gör med verktyget `perf`. 


* I katalogen `/perf-map-agent` finns ett gäng prestanda-mätnings-skript redan utkopierade från <https://github.com/jvm-profiling-tools/perf-map-agent>). I katalogen `~/bin` finns lite länkar till de som du kan köra direkt.
	 
* I katalogen `/perf-map-agent/FlameGraph` finns ytterligare ett par skript förberedda från <https://github.com/brendangregg/FlameGraph>

Sätt miljövariabeln `FLAMEGRAPH_DIR` till där dessa skript finns

	export FLAMEGRAPH_DIR=/perf-map-agent/FlameGraph

Ta reda på process-id:t för din java-process

	jps
	
Spela in events (metodanrop i detta fall) med linux-verktyget `perf` översätt dem till java-metodnamn med `perf-map-agent` och rita en flame-graph med `FlameGraph`-skripten:

	~/bin/perf-java-flames <process-id för din java-process>
	
Efter ett tag skapas en fil

	flamegraph-<pid>.svg
	
I mitten av körningen som genererar en flamegraph-fil är inspelningen av events klar. Då kan du växla till den terminalen som kör `loadtest.sh` och avbryta det med <kbd>CTRL</kbd>+<kbd>C</kbd> så får maskinen mer resurser att köra klart utritandet av grafen.

Kopiera `flamegraph-<pid>.svg` filen till ~ec2-user så du lätt kan kopiera hem den via `scp`

	cp	flamegraph*.svg ~ec2-user
	
På din maskin, hämta hem filen

	scp ec2:*.svg .
	
Öppna filen i nån svg-läsare, Google Chrome funkar bäst	
I den fångade filen kan du ibland stöta på många fall av `[unknown]`. Detta beror på en optimering som JVM:en gör som förstör spårningen uppåt i stacken av metodanrop. En speciell JVM-flagga kan hjälpa att återställa detta.

Starta om din java-process med en ny jvm-flagga. Avbryt den som redan kör med <kbd>CTRL</kbd>+<kbd>C</kbd> eller skicka `kill [process-id]` i en annan terminal.

	export JAVA_OPTS=-XX:+PreserveFramePointer
	./hello-dataloader-1.0-SNAPSHOT/bin/hello-dataloader
	
Kör nu om lasttestet och kör om kommandona som ritar ut en flamegraph.
	
	
## Diskussion om vad undersökningen gav

* Diskutera resultaten med din labbkompis. Var ligger flaskhalsen?
* Läs koden
* Läs koden i tredjepartsbibliotek
* Föreslå förbättringar



### Öppna frågor

* Vad är för/nackdelen med flamegraphs?
* Hur gör man om man inte kör under Linux? (googla)
	

### Överkurs

Eventuellt kan din fil fortfarande sakna viktiga led i metodanropen, då kan man göra om körningen med några miljövariabler satta. Det som saknas beror på fenomenen inlining (att vissa metodanrop optimeras bort genom att metodkroppens kod klistras in i en existerande metod till exempel).

För att få lite högre upplösning på din graf, sätt dem och kör om `perf-java-flames` (med lasttestet igång igen om du stoppat det).

	export PERF_MAP_OPTIONS=unfoldall
	export PERF_COLLAPSE_OPTS=--inline
