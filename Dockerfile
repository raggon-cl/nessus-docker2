# ============================================================
#  Imagen base: Debian Bookworm (slim)
#  Justificación: Nessus distribuye paquetes .deb oficiales.
#  Debian slim ofrece compatibilidad total con el instalador
#  de Tenable sin el peso de una imagen completa (~30% menor).
# ============================================================
FROM debian:bookworm-slim

# ------------------------------------------------------------
# Metadatos de la imagen (buena práctica OCI)
# ------------------------------------------------------------
LABEL maintainer="tu-usuario@correo.com"
LABEL version="1.0.0"
LABEL description="Tenable Nessus containerizado para INY1105"

# ------------------------------------------------------------
# Variables de entorno para instalación no interactiva.
# DEBIAN_FRONTEND=noninteractive evita que apt-get se detenga
# esperando input del usuario durante el build.
# ------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive
ENV NESSUS_VERSION="10.12.0"
ENV NESSUS_PACKAGE="Nessus-${NESSUS_VERSION}-debian10_amd64.deb"

# ------------------------------------------------------------
# Instalación de dependencias del sistema en una sola capa.
# RUN combinados con && reducen el número de capas.
# rm -rf /var/lib/apt/lists/* limpia el caché en la misma capa.
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    libssl3 \
    ca-certificates \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Descarga e instalación del paquete oficial de Nessus.
# El .deb se elimina al finalizar para reducir el tamaño
# de la capa resultante.
# ------------------------------------------------------------
RUN wget -q \
    "https://www.tenable.com/downloads/api/v2/pages/nessus/files/${NESSUS_PACKAGE}" \
    -O /tmp/${NESSUS_PACKAGE} \
    && dpkg -i /tmp/${NESSUS_PACKAGE} \
    && rm -f /tmp/${NESSUS_PACKAGE}

# ------------------------------------------------------------
# VOLUME — Puntos de montaje persistentes.
#
# /opt/nessus                    → Named Volume: plugins,
#                                  base de datos y configuración.
# /opt/nessus/var/nessus/logs    → Bind Mount: logs accesibles
#                                  desde el host para el SIEM.
# ------------------------------------------------------------
VOLUME ["/opt/nessus", "/opt/nessus/var/nessus/logs"]

# ------------------------------------------------------------
# Puerto 8834: interfaz web HTTPS de Nessus.
# EXPOSE es declarativo; el mapeo real ocurre en compose.
# ------------------------------------------------------------
EXPOSE 8834

# ------------------------------------------------------------
# Inicia el daemon de Nessus y mantiene el contenedor activo.
# ------------------------------------------------------------
CMD ["/bin/bash", "-c", "/opt/nessus/sbin/nessus-service -D && tail -f /dev/null"]
