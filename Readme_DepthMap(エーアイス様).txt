//////////////////////////////////////////////////////////////////////////////
// DepthMap for MMD/MMM
// 2014/10/12 ���Ń����[�X
//////////////////////////////////////////////////////////////////////////////

������
Depth Map���쐬����|�X�g�G�t�F�N�g�ł��B
MMD/MMM����摜���邢�͓���Ƃ��ďo�͂��Ă��܂���2D�ƂȂ�[�x���͎����Ă��܂��܂����A
�J�������猩�Ď�O�𔒁A����������ƕ\��Depth Map�i�O���[�X�P�[���j����邱�ƂŐ[�x����邱�Ƃ��o���܂��B

���After Effects�ȂǂɎg�p���邱�Ƃ�z�肵�Ă��܂��B

�uDepthMap(znear����)�v
zfar�݂̂ł̍��t�H�O����

�uDepthMap(znear�L��)�v
zNear�AzFar�����̍��t�H�O���삪�\


����F�G�[�A�C�X


���g����
==============================================================================
�EMikuMikuDance
DepthMap.x��ǂݍ��ށB

�iznear�����Łj
���t�H�O�̋�����ς������ꍇ�́ADepth.fxsub�t�@�C�����������ȂǂŊJ���A9�s�ڂ́ufloat zfar = 200;�v
�̒l��ύX���邱�Ƃ�far�i���t�H�O�̋����j��ύX���邱�Ƃ��ł��܂��B

�iznear�L��Łj
Depth.fxsub�t�@�C�����������ȂǂŊJ���A11�s�ڂ́ufloat znear = 20;�v12�s�ڂ́ufloat zfar = 80;�v
�̒l��ύX���邱�ƂŁA���t�H�O�̋�����ύX���邱�Ƃ��ł��܂��B
�@�Eznear �̓J�������猩�Ď�O�̍��t�H�O����
�@�Ezfar�̓J�������猩�Č�̍��t�H�O����
���d�l��A����ɓ����l�͈̔͂́uznear < zfar�v�ƂȂ�܂��B

�EMikuMikuMoving
DepthMap.fx��ǂݍ��ށB

�G�t�F�N�g�v���p�e�B�p�����[�^

zFar �@ �E�E�E�@Far�̋����̑���
�iznear�L��Łj
zNear�@�E�E�E�@Near�̋����̑���

��1 MMM�͓��I�p�[�X�ɂ��Ή����Ă��܂��B
��2 �d�l��A����ɓ����l�͈̔͂́uznear < zfar�v�ƂȂ�܂��B


---


�ETips : ��{�͉�ʑS�̂ɂ�����悤�ɂȂ��Ă��܂����A�G�t�F�N�g�t�@�C�����ȉ��̂悤�ɕύX���邱�Ƃ�
���f����A�N�Z�T���ȂǂɌʂɂ����邱�Ƃ��o���܂��B

�P�D�uDepth.fxsub�v�� �uDepth.fx�v�Ɗg���q�����l�[��
�Q�D�uDepth.fx�v�����f���A�A�N�Z�T���ɃG�t�F�N�g���蓖��


�Ȃ��A�o�͂���DepthMap�f����After Effects�Łu�I�o�v�G�t�F�N�g��������ƕ֗��ɁB


���ƁuDepthMap.fx�v�̂Q�s��
�u//#define USE_DEPTH_INVERSE�v��
�u#define USE_DEPTH_INVERSE�v
�ƃR�����g�A�E�g���O�����ƂŔ������]�ł��܂��B



�G�t�F�N�g�z�z�ꏊ
http://seiga.nicovideo.jp/seiga/im4372355

�Ȃɂ����C�Â��̓_������Ή��L�܂�
http://twitter.com/aice_black



���X�V����
2015/7/31
zNear�Œǉ�

2015/1/1
zFar�ǉ��ɔ����R�[�h���኱�ύX

2014/10/17
�J�����ʒu�A�p�x�ɂ���ĕςȍ����e��������o�O�C��


���Ɛ�
==============================================================================
���ρE�Ĕz�z�͎��R�ł��B�A��������܂���B

���t�@�C�����g�p���Đ����������Ȃ鑹�Q�ɑ΂��Ă��A�����͈�ؐӔC�𕉂��܂���B
���ȐӔC�ł��g�p���������B