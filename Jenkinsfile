def artserver = Artifactory.server('repository.terradue.com')
def buildInfo = Artifactory.newBuildInfo()
buildInfo.env.capture = true

pipeline {


  options {
    // Kepp 5 builds history
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }

  agent { 
    node { 
      // community builder
      label 'ci-community' 
    }
  }

  stages {

    // Let's go!
    // stage('Package S1') {
    //   steps {
        
    //     withMaven(
    //       // Maven installation declared in the Jenkins "Global Tool Configuration"
    //       maven: 'apache-maven-3.0.5' ) {
    //       sh 'mvn -X -e -B deploy -D mission=S1'
    //     }

    //   }
    // }
    
   stage('Package ENVISAT') {
     steps {

       withMaven(
          Maven installation declared in the Jenkins "Global Tool Configuration"
         maven: 'apache-maven-3.0.5' ) {
         sh 'mvn -B deploy -Dmission=ENVISAT'
       }

     }
   }
    
 //   stage('Package RS2') {
 //     steps {
        
  //      withMaven(
          // Maven installation declared in the Jenkins "Global Tool Configuration"
    //      maven: 'apache-maven-3.0.5' ) {
  //        sh 'mvn -B deploy -Dmission=RS2'
  //      }

    //  }
 //   }
    
 //   stage('Package TSX') {
 //     steps {
        
   //     withMaven(
          // Maven installation declared in the Jenkins "Global Tool Configuration"
   //       maven: 'apache-maven-3.0.5' ) {
     //     sh 'mvn -B deploy -Dmission=TSX'
    //    }

   //   }
    //}
    
  }
}
