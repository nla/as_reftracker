pipeline {
    agent any

    environment {
        APP_NAME = "as_reftracker"
    }
    options {
        skipDefaultCheckout(true)
    }
    
    stages {

        stage('Checkout') {
            steps {
                deleteDir()
                checkout scm
            }
        }

        stage('Build & Package') {
            steps {
               
                script {
                    // Compute version once and make it available globally across stages
                    env.VERSION = sh(
                        script: 'grep -m 1 "<version>" pom.xml | sed "s/<version>\\(.*\\)<\\/version>/\\1/" | tr -d " "', 
                        returnStdout: true
                    ).trim()
                    
                    env.WAR_FILE = "${env.APP_NAME}-${env.VERSION}.war"
                    echo "Packaging project contents into ${env.WAR_FILE}..."
                    
                    // Package using Java's jar tool
                    if (fileExists("content-to-zip")) {
                        dir("content-to-zip") {
                            sh "jar -cvf ../${env.WAR_FILE} *"
                        }
                    } else {
                        sh "jar -cvf ${env.WAR_FILE} ."
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-deployer',
                    usernameVariable: 'NEXUS_USERNAME',
                    passwordVariable: 'NEXUS_PASSWORD'
                )]) {
                    withMaven(
                        maven: 'Maven 3',
                        jdk: 'JDK 8',
                        mavenSettingsConfig: 'Global_Maven_Settings',
                        mavenLocalRepo: '.m2/repository'
                    ) {
                        sh '''
                            set -euo pipefail

                            if [[ ! -f "$WAR_FILE" ]]; then
                                echo "ERROR: Missing artifact $WAR_FILE"
                                ls -lah
                                exit 1
                            fi

                            if [[ "$VERSION" == *"-SNAPSHOT"* ]]; then
                                REPO_URL="https://dev.nla.gov.au/nexus/content/repositories/nla-snapshots"
                            else
                                REPO_URL="https://dev.nla.gov.au/nexus/content/repositories/nla"
                            fi

                            TARGET_URL="${REPO_URL}/au/gov/nla/${APP_NAME}/${VERSION}/${WAR_FILE}"
                            echo "Uploading $WAR_FILE to $TARGET_URL"

                            curl --fail --show-error --silent \
                                --write-out "HTTP %{http_code}\\n" \
                                -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
                                --upload-file "$WAR_FILE" \
                                "$TARGET_URL"
                        '''
                    }
                }
            }
        }
    }
}
