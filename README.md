# Det brinner i java

Den här övningen går ut på att lära sig att mäta och felsöka ett prestandaproblem i en existerande applikation.

## A. Systemet vi ska undersöka

Vi ska undersöka en servertjänst som vi kallar hello-dataloader, som exponerar lite data via GraphQL. GraphQL är ett frågespråk för 

För att bygga:

	git clone https://github.com/rrva/hello-dataloader
	cd hello-dataloader
	./gradlew repackage
	
Om allt gått bra har du nu filen _build/distributions/hello-dataloader-1.0-SNAPSHOT.{tar/zip}_	 		
	
Packa upp filen build/distributions/hello-dataloader-1.0-SNAPSHOT.{tar/zip} (för linux/mac resp windows)	
	
För att köra:

	cd hello-dataloader-1.0-SNAPSHOT/bin
	./hello-dataloader
	
Utforska appen, besök <http://localhost:8080/graphiql.html>

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

Det vi har här är ett system skrivet i Kotlin (nästan som Java), som kör på JVM:en, som servar lite dummy-data via GraphQL.

Vi ska nu lägga på lite last.

Installera lasttest-verktyget siege

	brew install siege

Kör en lastgenerator som skickar 6 samtidiga graphql-frågor till vår app.

	cd src/test/resources/
	./loadtest.sh

## B. Skapa en testmiljö

### 1. Installera Amazon AWS EC2 commandline tools

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

	export PATH=$PATH:Library/Python/2.7/bin
	
Om du vill, gör PATH-inställingen permanent

	echo 'export PATH=$PATH:Library/Python/2.7/bin' >> ~/.bashrc
	
	
#### Konfigurera säkerhetsnyckel för aws-cli

	aws configure

Ange en nyckel från <https://docs.google.com/spreadsheets/d/15N-IyO5bFvOB5-3zg_XE7giiHOw9B0JJ6gZJLNAxqd0/edit?usp=sharing>
		
	 		
	

### TA EN PAUS KANSKE?

	 		
### C. Starta en EC2-instans

Vi kommer att begära att en instans startas enligt vad som står i filen ec2-tprg.json som ligger i git-repot du klonade

	aws ec2 request-spot-instances --block-duration-minutes 120 --launch-specification file://ec2.json
	
#### Hitta ip-address för din EC2-instans

	aws ec2 describe-instances --query "Reservations[*].Instances[*].PublicIpAddress" --output=text	
Om detta inte gått bra, kanske din spot instance request slagit fel. prova då med: 

	aws ec2 describe-spot-instance-requests
	
Om spot instance request av någon anledning inte funkar, skapa en vanlig instans utan spot-marknadspris:

	aws ec2 run-instances --cli-input-json file://ec2.json
		
	
#### Konfigurera ssh

För bekvämlighet, kan vi konfigurera ssh-nyckeln som krävs för att logga in.

Kopiera tprg-key.pem från google doc:et och spara som `~/.ssh/tprg-key.pem`
	
Se till att filen bara är läsbar av din användare:
	
	chmod 600 ~/.ssh/tprg-key.pem
	
Lägg i i filen **~/.ssh/config**:	
	
```
Host ec2-tprg
    HostName <ip-adress för din instans>
    User ec2-user
    IdentityFile ~/.ssh/tprg-key.pem
    IdentitiesOnly yes
    StrictHostKeyChecking no
```

#### Kontrollera inloggning via ssh

	ssh ec2-trpg
	
Om allt gått bra får du en bash-prompt på din nya instans.







