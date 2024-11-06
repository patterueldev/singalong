include("client-app-admin")
project(":client-app-admin").projectDir = file("apps/admin")

include("client-app-controller")
project(":client-app-controller").projectDir = file("apps/controller")

include("client-app-player")
project(":client-app-player").projectDir = file("apps/player")

// Packages - Core
include("client-package-singalong_api_client")
project(":client-package-singalong_api_client").projectDir = file("client/packages/singalong_api_client")

include("client-package-shared")
project(":client-package-shared").projectDir = file("client/packages/shared")

include("client-package-common")
project(":client-package-common").projectDir = file("client/packages/common")
include("client-package-commonds")
project(":client-package-commonds").projectDir = file("client/packages/commonds")

// Packages - Features
include("client-package-adminfeature")
project(":client-package-adminfeature").projectDir = file("client/packages/adminfeature")
include("client-package-adminfeatureds")
project(":client-package-adminfeatureds").projectDir = file("client/packages/adminfeatureds")

include("client-package-connectfeature")
project(":client-package-connectfeature").projectDir = file("client/packages/connectfeature")
include("client-package-connectfeatureds")
project(":client-package-connectfeatureds").projectDir = file("client/packages/connectfeatureds")

include("client-package-downloadfeature")
project(":client-package-downloadfeature").projectDir = file("client/packages/downloadfeature")
include("client-package-downloadfeature_ds")
project(":client-package-downloadfeature_ds").projectDir = file("client/packages/downloadfeature_ds")

include("client-package-playerfeature")
project(":client-package-playerfeature").projectDir = file("client/packages/playerfeature")
include("client-package-playerfeatureds")
project(":client-package-playerfeatureds").projectDir = file("client/packages/playerfeatureds")

include("client-package-sessionfeature")
project(":client-package-sessionfeature").projectDir = file("client/packages/sessionfeature")
include("client-package-sessionfeatureds")
project(":client-package-sessionfeatureds").projectDir = file("client/packages/sessionfeatureds")

include("client-package-songbookfeature")
project(":client-package-songbookfeature").projectDir = file("client/packages/songbookfeature")
include("client-package-songbookfeatureds")
project(":client-package-songbookfeatureds").projectDir = file("client/packages/songbookfeatureds")