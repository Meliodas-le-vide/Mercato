import apiClient from '../client';

export interface RecruiterKyc {
  id: number;
  userId: number;
  organizationName?: string;
  organizationType?: 'CLUB' | 'AGENCE' | 'CENTRE_FORMATION' | 'INDEPENDANT';
  jobTitle?: string;
  recruitmentZone?: string;
  bio?: string;
  isProfileComplete: boolean;
  verificationStatus: 'PENDING' | 'VERIFIED' | 'REJECTED';


  identityDocumentType?:
    | 'CNI'
    | 'PASSEPORT'
    | 'SIRET'
    | 'RCS'
    | 'CARTE_AGENT_FIFA'
    | 'ATTESTATION_CLUB'
    | 'AUTRE';
  identityDocumentNumber?: string;
  identityDocumentUrl?: string;
  licenseNumber?: string;
  businessProofUrl?: string;


  kycSubmittedAt?: string;
  verifiedAt?: string;
  verifiedBy?: number;
  rejectedAt?: string;
  rejectedBy?: number;
  rejectionReason?: string;

  createdAt: string;
  updatedAt: string;


  user?: {
    id: number;
    firstname: string;
    lastname: string;
    email: string;
    phone?: string;
    Profile_image?: string;
  };
}

export const recruitersService = {

  async getAll(status?: string): Promise<RecruiterKyc[]> {
    const { data } = await apiClient.get('/admin/recruiters', {
      params: { status },
    });
    return data.data;
  },


  async getById(id: number): Promise<RecruiterKyc> {
    const { data } = await apiClient.get(`/admin/recruiters/${id}`);
    return data.data;
  },


  async verify(
    id: number,
    status: 'VERIFIED' | 'REJECTED',
    rejectionReason?: string
  ): Promise<void> {
    await apiClient.patch(`/admin/recruiters/${id}/verify`, {
      status,
      rejectionReason,
    });
  },
};