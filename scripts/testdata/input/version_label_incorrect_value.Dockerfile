# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# FAIL: PRODUCT_VERSION is expected and is the name of the build arg, not VERSION
# This dockerfile will set the value to 8.6 which comes from the UBI container but
# does not match the PRODUCT_VERSION we expect
FROM registry.access.redhat.com/ubi8/ubi-minimal:8.6 as default

ARG BIN_NAME
# Export BIN_NAME for the CMD below, it can't see ARGs directly.
ENV BIN_NAME=$BIN_NAME

ARG VERSION
ARG PRODUCT_REVISION
ARG PRODUCT_NAME=$BIN_NAME
# TARGETOS and TARGETARCH are set automatically when --platform is provided.
ARG TARGETOS TARGETARCH

LABEL maintainer="Team RelEng <team-rel-eng@hashicorp.com>"
LABEL version=$VERSION
LABEL revision=$PRODUCT_REVISION

COPY dist/$TARGETOS/$TARGETARCH/$BIN_NAME /bin/

USER 100
CMD ["/bin/$BIN_NAME", "default"]
