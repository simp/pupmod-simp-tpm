#!/bin/bash
#
# Copyright (c) 2014, Dan Yocum (dyocum@redhat.com), Wei Gang (gang.wei@intel.com), et al.
# All rights reserved.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# This script will update the tboot policy
# for a Measured Launch Environment (mle) and write the policy to the NVRAM on
# the Trusted Platform Module (tpm) on the mobo.
#
# For complete details, and a cure for insomnia, read the complete documents
# policy_v2.txt and lcptools2.txt found in /usr/share/doc/tboot-1.7.0/.

set -e

if [ $UID -ne 0 ]; then
    echo "This can only be executed as root.  Aborting."
    exit 1
fi

if [ $# -ne 1 ]; then
    echo "Usage: $0 <20_character_passwrd>"
    exit 1
fi

# TPM password - MUST BE 20 CHARACTERS!
#PASSWORD="20 character passwrd"
PASSWORD="$1"

if [ `echo -n $PASSWORD | wc -c` -ne 20 ]; then
    echo "Password is not 20 characters long.  Please try again."
    exit 1
fi

# Grab tboot kernel params from the grub files
if [[ -f /etc/default/grub-tboot ]]; then
    source /etc/default/grub-tboot
else
    GRUB_CMDLINE_TBOOT="logging=serial,memory,vga min_ram=0x2000000"
fi

# Clean up the files after we're done?
CLEAN_UP=false

if [[ ! -d /root/txt ]]; then
  mkdir /root/txt
fi
cd /root/txt/

# clean nvram
# tpmnv_relindex -p "$PASSWORD" -i 0x20000001 || true

# Clean up the files before we start!  vl.pol is simply appended to, not
# written over - might as well clean up everything else, too.
rm -f vl.pol

echo "g. Generate the tboot policy to control expected kernel and initrd"
tb_polgen --create --type nonfatal vl.pol

# set the boot CMD_LINE
# tboot and grub v1 don't play well together (e.g., an extra space between
# cli options can cause tboot to fail), we need to use sed instead of awk.
# Apparently this is not an issue with grub2
CMD_LINE="`cat /proc/cmdline | cut -d ' ' -f 1 --complement` intel_iommu=on"

# set the kernel image
KERNEL_IMG=`ls /boot/ | grep vmlinuz-[23] | head -n1`
KERNEL_PATH="/boot/${KERNEL_IMG}"

# set the initramfs image
INITRAMFS_IMG=`ls /boot/ | grep initramfs-[23] | head -n1`
INITRAMFS_PATH="/boot/${INITRAMFS_IMG}"

# finally, create the policy for the images
tb_polgen --add --num 0 --pcr none --hash image --cmdline "$CMD_LINE" --image ${KERNEL_PATH} vl.pol
tb_polgen --add --num 1 --pcr 19 --hash image --cmdline "" --image ${INITRAMFS_PATH} vl.pol

echo "l. Write the tboot policy (from vl.pol) into the NV index"
lcp_writepol -i 0x20000001 -f vl.pol -p "$PASSWORD"

echo ""
echo "--------------------------------------------------------------------------------"
echo ""
echo "Updated policy based on these parameters:"
echo "    owner password:  supplied"
echo "    tboot cmdline:   ${GRUB_CMDLINE_TBOOT}"
echo "    kernel cmdline:  ${CMD_LINE}"
echo "    kernel image:    ${KERNEL_PATH}"
echo "    initramfs image: ${INITRAMFS_PATH}"

if [ $CLEAN_UP = "true" ]; then
    rm -f vl.pol
fi
