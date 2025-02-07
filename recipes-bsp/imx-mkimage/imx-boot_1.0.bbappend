require ${@ 'imx-boot-signature.inc' if 'hab' in d.getVar('OVERRIDES').split(':') else ''}
require ${@ 'imx-boot-ahab-signature.inc' if 'ahab' in d.getVar('OVERRIDES').split(':') else ''}
