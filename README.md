# Efossils

Gestor multirepositorio para [fossil-scm](https://www.fossil-scm.org)

# Requerimientos

  *  fossil 2.7
  *  Elixir v1.6.6
  *  npm v6
  *  PostgreSQL
  *  timeout, git

# Organizaciones

Actualmente la plataforma no gestiona organizaciones -aun no determino la manera más acorde a fossil-, pero actualmente permite el simbolo @ en los nombres de repositorios, se recomiendo agrupar utilizando este nombre, ej: dns@somxslibres.net.

# Instalación

Una vez se tenga cumplido los requerimientos.

  -  una vez clonado el repositorio [https://chiselapp.com/user/bit4bit/repository/efossils], es volverlo un proyecto hijo para facilitar actualizaciones posteriores. [https://www.fossil-scm.org/xfer/doc/trunk/www/childprojects.wiki]
  -  configurar los paramétros para acceder a gestor de base datos y enviar correo electrónicos esto en el archivo *config/prod.secret.exs*.
  -  ingresar a assets y ejecutar 'brunch build'
  -  de nuevo en la carpeta princial ejecutar 'mix phx.digest'
  -  crear base de datos `MIX_ENV=prod mix ecto.create`
  -  crear esquema inicial `MIX_ENV=prod mix ecto.migrate`
  -  Inicializar el servidor, para esto son necesarias las siguientes variables de entorno:
      *  PORT=4001
      *  MIX_ENV=prod
      *  EFOSSILS\_FOSSIL\_BASE_URL="https://efossils.midominio.net"
      *  EFOSSILS\_FEDERATED\_NAME="Midominio" ;identificador en la red de repositorios
      *  EFOSSILS\_FOSSIL_BIN="/usr/local/bin/fossil"
      *  EFOSSILS\_REPOSITORY\_PATH="/efossils/repositorios"
      *  EFOSSILS\_WORK\_PATH="/efossils/works"
      *  EFOSSILS\_EMAIL\_FROM\_NAME="Efossils"
      *  EFOSSILS\_EMAIL\_FROM\_EMAIL="no-reply@localhost.localhost"

En caso de no tener configurado el servicio de correo electronico, puede confirmar los usuarixs usando
<pre>
MIX_ENV=prod efossils.confirm.user <email>
</pre>
O si usted desea omitir la confirmación edite *config/config.exs* y retire de las extensiones de pow estas son: PowEmailConfirmation,PowResetPassword.

Ejemplo de linea de comando:

<pre>
PORT=4001 MIX_ENV=prod EFOSSILS_FOSSIL_BASE_URL="https://efossils.somxslibres.net" EFOSSILS_FEDERATED_NAME="SomxsLibres" EFOSSILS_FOSSIL_BIN="/usr/local/bin/fossil" EFOSSILS_REPOSITORY_PATH="/efossils/efossils/priv/data/repositories" EFOSSILS_WORK_PATH="/efossils/efossils/priv/data/works" EFOSSILS_EMAIL_FROM_NAME="Efossils" EFOSSILS_EMAIL_FROM_EMAIL="no-reply@localhost.localhost" mix do compile, phx.server
</pre>

## TAREAS COMUNES

### Configuración de Servidor SMTP

Para el envio de correos se utiliza la librería Swoosh, vease está para determinar como configurar los adapters.

### Cambio de version de ejecutable *fossil*

Si se ha actualizado el ejecutable es necesario reconstruir los *.efossils puede usar la tarea *efossils.repositories.rebuild*.
<pre>
MIX_ENV=prod mix efossils.repositories.rebuild
</pre>

# Usan

  *  [efossils.somxslibres.net](https://efossils.somxslibres.net)
